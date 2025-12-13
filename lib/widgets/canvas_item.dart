import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';
import '../state/canvas_provider.dart';
import 'corner_handles.dart';

/// Custom painter for corner resize handles that wrap around corners

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
  // Gesture state for dragging this item
  Offset? _dragStartLocalPosition;
  Offset? _currentDragOffset;

  @override
  Widget build(BuildContext context) {
    final isSelected = ref.watch(selectedItemIdProvider) == widget.item.id;

    final displayX = widget.item.x + (_currentDragOffset?.dx ?? 0.0);
    final displayY = widget.item.y + (_currentDragOffset?.dy ?? 0.0);
    final displayScale = widget.item.scale * widget.additionalScale;

    // Scale border properties proportionally with the image size
    final baseBorderRadius = 21.0;
    final baseBorderWidth = 3.0;

    final scaledBorderRadius = baseBorderRadius * displayScale;
    final scaledBorderWidth = baseBorderWidth * displayScale;

    return Positioned(
      left: 3500 + displayX,
      top: 3500 + displayY,
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: widget.onSelect,
          // Only enable drag gestures when this item is selected
          onScaleStart: isSelected
              ? (details) {
                  setState(() {
                    _dragStartLocalPosition = details.localFocalPoint;
                    _currentDragOffset = Offset.zero;
                  });
                }
              : null,
          onScaleUpdate: isSelected
              ? (details) {
                  if (_dragStartLocalPosition != null) {
                    setState(() {
                      // Only handle single-finger drags
                      // Ignore multi-finger gestures (zoom) to prevent item resizing
                      if (details.pointerCount == 1) {
                        _currentDragOffset =
                            details.localFocalPoint - _dragStartLocalPosition!;
                      }
                    });
                  }
                }
              : null,
          onScaleEnd: isSelected
              ? (details) {
                  if (_dragStartLocalPosition != null) {
                    // Find this item in the board
                    final itemIndex = widget.board.items.indexWhere(
                      (i) => i.id == widget.item.id,
                    );
                    if (itemIndex != -1) {
                      final updatedItem = widget.item.copyWith(
                        x: widget.item.x + (_currentDragOffset?.dx ?? 0.0),
                        y: widget.item.y + (_currentDragOffset?.dy ?? 0.0),
                      );

                      final newItems = List<BoardItem>.from(widget.board.items);
                      newItems[itemIndex] = updatedItem;

                      ref
                          .read(boardListProvider.notifier)
                          .updateBoard(widget.board.copyWith(items: newItems));
                    }

                    setState(() {
                      _dragStartLocalPosition = null;
                      _currentDragOffset = null;
                    });
                  }
                }
              : null,
          child: Transform.rotate(
            angle: widget.item.rotation,
            child: Stack(
              children: [
                // Image container (full size, no border)
                Container(
                  width: widget.item.width * displayScale,
                  height: widget.item.height * displayScale,
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
                    width: widget.item.width * displayScale,
                    height: widget.item.height * displayScale,
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
                      widget.item.width * displayScale,
                      widget.item.height * displayScale,
                    ),
                    painter: CornerHandlePainter(
                      handleLength: 12.0 * displayScale,
                      handleThickness: 8.0 * displayScale,
                      handleColor: Color.fromARGB(255, 235, 235, 235),
                      borderRadius: scaledBorderRadius,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(WidgetRef ref) {
    if (widget.item.imageSource.startsWith('http')) {
      return Image.network(widget.item.imageSource, fit: BoxFit.cover);
    }

    // Relative Pfade (neu): Wir müssen das Dokumenten-Verzeichnis holen
    final appDirAsync = ref.watch(appDocumentsDirectoryProvider);

    return appDirAsync.when(
      data: (dir) {
        final fullPath = '${dir.path}/${widget.item.imageSource}';
        final file = File(fullPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            cacheWidth: 1000, // RAM-Optimierung
          );
        }
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.orange),
        );
      },
      loading: () => const SizedBox.shrink(), // Oder kleiner Platzhalter
      error: (_, __) =>
          const Center(child: Icon(Icons.error, color: Colors.red)),
    );
  }
}
