import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board.dart';
import '../models/board_item.dart';
import '../services/image_transform_service.dart';
import '../state/board_provider.dart';
import '../state/canvas_provider.dart';
import 'corner_handles.dart';

class CanvasItem extends ConsumerStatefulWidget {
  final BoardItem item;
  final Board board;
  final double additionalScale;
  final VoidCallback? onSelect;

  const CanvasItem({
    super.key,
    required this.item,
    required this.board,
    this.additionalScale = 1.0,
    this.onSelect,
  });

  @override
  ConsumerState<CanvasItem> createState() => _CanvasItemState();
}

class _CanvasItemState extends ConsumerState<CanvasItem> {
  // Drag State
  Offset? _dragStartLocalPosition;
  Offset? _currentDragOffset;

  // Resize State
  ResizeHandle? _activeHandle;
  Offset? _resizeStartPosition;
  double? _startWidth;
  double? _startHeight;
  double? _startX;
  double? _startY;
  ResizeResult? _currentResize;

  bool get _isResizing => _activeHandle != null;

  @override
  Widget build(BuildContext context) {
    final isSelected = ref.watch(selectedItemIdProvider) == widget.item.id;
    final displayScale = widget.item.scale * widget.additionalScale;

    // Aktuelle Werte (mit pending changes)
    final currentX = _currentResize?.x ?? widget.item.x;
    final currentY = _currentResize?.y ?? widget.item.y;
    final currentWidth = _currentResize?.width ?? widget.item.width;
    final currentHeight = _currentResize?.height ?? widget.item.height;

    final displayX = currentX + (_currentDragOffset?.dx ?? 0.0);
    final displayY = currentY + (_currentDragOffset?.dy ?? 0.0);

    // Derive selection chrome dimensions from the item's actual visible
    // size so border + handles stay visually balanced as the item is
    // resized (clamped so they neither vanish nor dominate at extremes).
    final visualWidth = currentWidth * displayScale;
    final visualHeight = currentHeight * displayScale;
    final referenceSize = math.min(visualWidth, visualHeight);

    final scaledBorderWidth = (referenceSize * 0.015).clamp(2.0, 5.0);
    final scaledBorderRadius = (referenceSize * 0.07).clamp(8.0, 28.0);
    final scaledHandleLength = (referenceSize * 0.09).clamp(10.0, 22.0);
    final scaledHandleThickness = (referenceSize * 0.05).clamp(6.0, 12.0);

    return Positioned(
      left: 3500 + displayX,
      top: 3500 + displayY,
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: widget.onSelect,
          onScaleStart: isSelected ? _onScaleStart : null,
          onScaleUpdate: isSelected ? _onScaleUpdate : null,
          onScaleEnd: isSelected ? _onScaleEnd : null,
          child: Transform.rotate(
            angle: widget.item.rotation,
            child: Transform.scale(
              scaleX: widget.item.flipHorizontal ? -1.0 : 1.0,
              child: Stack(
                children: [
                  // Image container
                  Container(
                    width: currentWidth * displayScale,
                    height: currentHeight * displayScale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(scaledBorderRadius),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(scaledBorderRadius),
                      child: _buildImageContent(ref),
                    ),
                  ),
                  // Border overlay (only when selected)
                  if (isSelected)
                    Container(
                      width: currentWidth * displayScale,
                      height: currentHeight * displayScale,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blueAccent,
                          width: scaledBorderWidth,
                        ),
                        borderRadius: BorderRadius.circular(scaledBorderRadius),
                      ),
                    ),
                  // Corner resize handles (only when selected)
                  if (isSelected)
                    CustomPaint(
                      size: Size(
                        currentWidth * displayScale,
                        currentHeight * displayScale,
                      ),
                      painter: CornerHandlePainter(
                        handleLength: scaledHandleLength,
                        handleThickness: scaledHandleThickness,
                        handleColor: const Color.fromARGB(255, 235, 235, 235),
                        borderRadius: scaledBorderRadius,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    final displayScale = widget.item.scale * widget.additionalScale;
    final currentWidth = widget.item.width * displayScale;
    final currentHeight = widget.item.height * displayScale;
    final hitAreaSize = ImageTransformService.getHitAreaSize(displayScale);

    // Prüfe ob ein Corner-Handle getroffen wurde
    final handle = ImageTransformService.hitTestHandle(
      localPosition: details.localFocalPoint,
      itemWidth: currentWidth,
      itemHeight: currentHeight,
      hitAreaSize: hitAreaSize,
    );

    if (handle != null) {
      // Resize-Modus starten
      setState(() {
        _activeHandle = handle;
        _resizeStartPosition = details.localFocalPoint;
        _startWidth = widget.item.width;
        _startHeight = widget.item.height;
        _startX = widget.item.x;
        _startY = widget.item.y;
      });
    } else {
      // Drag-Modus starten
      setState(() {
        _dragStartLocalPosition = details.localFocalPoint;
        _currentDragOffset = Offset.zero;
      });
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount != 1) return; // Nur Single-Finger-Gesten

    if (_isResizing && _resizeStartPosition != null) {
      // Resize-Logik
      final displayScale = widget.item.scale * widget.additionalScale;
      final delta =
          (details.localFocalPoint - _resizeStartPosition!) / displayScale;

      final result = ImageTransformService.calculateResize(
        handle: _activeHandle!,
        startX: _startX!,
        startY: _startY!,
        startWidth: _startWidth!,
        startHeight: _startHeight!,
        delta: delta,
        maintainAspectRatio: true,
      );

      setState(() {
        _currentResize = result;
      });
    } else if (_dragStartLocalPosition != null) {
      // Drag-Logik
      setState(() {
        _currentDragOffset = details.localFocalPoint - _dragStartLocalPosition!;
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_isResizing && _currentResize != null) {
      // Resize abschließen - Board updaten
      _updateBoardItem(
        x: _currentResize!.x,
        y: _currentResize!.y,
        width: _currentResize!.width,
        height: _currentResize!.height,
      );

      setState(() {
        _activeHandle = null;
        _resizeStartPosition = null;
        _startWidth = null;
        _startHeight = null;
        _startX = null;
        _startY = null;
        _currentResize = null;
      });
    } else if (_dragStartLocalPosition != null) {
      // Drag abschließen - Board updaten
      final newPos = ImageTransformService.calculateDragPosition(
        startX: widget.item.x,
        startY: widget.item.y,
        dragDelta: _currentDragOffset ?? Offset.zero,
      );

      _updateBoardItem(x: newPos.dx, y: newPos.dy);

      setState(() {
        _dragStartLocalPosition = null;
        _currentDragOffset = null;
      });
    }
  }

  void _updateBoardItem({double? x, double? y, double? width, double? height}) {
    final itemIndex = widget.board.items.indexWhere(
      (i) => i.id == widget.item.id,
    );

    if (itemIndex != -1) {
      final updatedItem = widget.item.copyWith(
        x: x,
        y: y,
        width: width,
        height: height,
      );

      final newItems = List<BoardItem>.from(widget.board.items);
      newItems[itemIndex] = updatedItem;

      ref
          .read(boardListProvider.notifier)
          .updateBoard(widget.board.copyWith(items: newItems));
    }
  }

  Widget _buildImageContent(WidgetRef ref) {
    if (widget.item.imageSource.startsWith('http')) {
      return Image.network(widget.item.imageSource, fit: BoxFit.cover);
    }

    final appDirAsync = ref.watch(appDocumentsDirectoryProvider);

    return appDirAsync.when(
      data: (dir) {
        final fullPath = '${dir.path}/${widget.item.imageSource}';
        final file = File(fullPath);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover, cacheWidth: 1000);
        }
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.orange),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) =>
          const Center(child: Icon(Icons.error, color: Colors.red)),
    );
  }
}
