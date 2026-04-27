import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
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

  // Shader / ui.Image cache for posterization
  ui.Image? _cachedUiImage;
  String? _cachedImagePath;
  static Future<ui.FragmentProgram>? _posterizeProgramFuture;

  static Future<ui.FragmentProgram> _getPosterizeProgram() =>
      _posterizeProgramFuture ??= ui.FragmentProgram.fromAsset(
        'shaders/posterize.frag',
      );

  bool get _isResizing => _activeHandle != null;

  @override
  void dispose() {
    _cachedUiImage?.dispose();
    super.dispose();
  }

  Future<void> _loadUiImage(String fullPath) async {
    if (_cachedImagePath == fullPath) return;
    final bytes = await File(fullPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _cachedUiImage?.dispose();
        _cachedUiImage = frame.image;
        _cachedImagePath = fullPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = ref.watch(selectedItemIdProvider) == widget.item.id;
    final canvasScale = ref.watch(canvasScaleProvider);
    final displayScale = widget.item.scale * widget.additionalScale;

    // Aktuelle Werte (mit pending changes)
    final currentX = _currentResize?.x ?? widget.item.x;
    final currentY = _currentResize?.y ?? widget.item.y;
    final currentWidth = _currentResize?.width ?? widget.item.width;
    final currentHeight = _currentResize?.height ?? widget.item.height;

    final displayX = currentX + (_currentDragOffset?.dx ?? 0.0);
    final displayY = currentY + (_currentDragOffset?.dy ?? 0.0);

    // Keep a constant corner proportion relative to the rendered image size.
    final visualReference = math.min(
      currentWidth * displayScale,
      currentHeight * displayScale,
    );
    final scaledBorderRadius = visualReference * 0.07;

    final handlePadding = CornerHandleMetrics.handlePadding(canvasScale);

    return Positioned(
      left: 3500 + displayX - handlePadding,
      top: 3500 + displayY - handlePadding,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onSelect,
          onScaleStart: isSelected ? _onScaleStart : null,
          onScaleUpdate: isSelected ? _onScaleUpdate : null,
          onScaleEnd: isSelected ? _onScaleEnd : null,
          child: Padding(
            padding: EdgeInsets.all(handlePadding),
            child: Transform.rotate(
              angle: widget.item.rotation,
              child: Transform.scale(
                scaleX: widget.item.flipHorizontal ? -1.0 : 1.0,
                child: Stack(
                  clipBehavior: Clip.none,
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
                        child: _buildImageContent(
                          ref,
                          currentWidth: currentWidth,
                          currentHeight: currentHeight,
                          displayScale: displayScale,
                        ),
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
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(
                            scaledBorderRadius,
                          ),
                        ),
                      ),
                    // Corner resize handles (only when selected)
                    if (isSelected)
                      CustomPaint(
                        size: Size(
                          currentWidth * displayScale,
                          currentHeight * displayScale,
                        ),
                        painter: CircleHandlePainter(
                          radius: CornerHandleMetrics.radiusForCanvasScale(
                            canvasScale,
                          ),
                          offset: CornerHandleMetrics.offsetForCanvasScale(
                            canvasScale,
                          ),
                        ),
                      ),
                  ],
                ),
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
    final canvasScale = ref.read(canvasScaleProvider);
    final hitAreaSize = CornerHandleMetrics.hitAreaSize(canvasScale);
    final handlePadding = CornerHandleMetrics.handlePadding(canvasScale);

    // Strip padding offset so hit-test coordinates are relative to image origin
    final adjustedPosition =
        details.localFocalPoint - Offset(handlePadding, handlePadding);

    final handle = ImageTransformService.hitTestHandle(
      localPosition: adjustedPosition,
      itemWidth: currentWidth,
      itemHeight: currentHeight,
      hitAreaSize: hitAreaSize,
    );

    if (handle != null) {
      // Resize-Modus starten
      setState(() {
        _activeHandle = handle;
        _resizeStartPosition =
            details.localFocalPoint; // raw; delta cancels padding
        _startWidth = widget.item.width;
        _startHeight = widget.item.height;
        _startX = widget.item.x;
        _startY = widget.item.y;
      });
    } else {
      // Only drag when touch is inside the image — outer padding ring is resize-only
      final insideImage =
          adjustedPosition.dx >= 0 &&
          adjustedPosition.dy >= 0 &&
          adjustedPosition.dx <= currentWidth &&
          adjustedPosition.dy <= currentHeight;

      if (insideImage) {
        setState(() {
          _dragStartLocalPosition = details.localFocalPoint;
          _currentDragOffset = Offset.zero;
        });
      }
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

  Widget _buildImageContent(
    WidgetRef ref, {
    required double currentWidth,
    required double currentHeight,
    required double displayScale,
  }) {
    final item = widget.item;

    if (item.imageSource.startsWith('http')) {
      Widget image = Image.network(item.imageSource, fit: BoxFit.cover);
      return _applyEffects(
        image,
        item,
        currentWidth: currentWidth,
        currentHeight: currentHeight,
        displayScale: displayScale,
      );
    }

    final appDirAsync = ref.watch(appDocumentsDirectoryProvider);

    return appDirAsync.when(
      data: (dir) {
        final fullPath = '${dir.path}/${item.imageSource}';
        final file = File(fullPath);
        if (file.existsSync()) {
          // Trigger ui.Image load for posterization shader
          if (item.isPosterized && _cachedImagePath != fullPath) {
            _loadUiImage(fullPath);
          }
          Widget image = Image.file(file, fit: BoxFit.cover, cacheWidth: 1000);
          return _applyEffects(
            image,
            item,
            currentWidth: currentWidth,
            currentHeight: currentHeight,
            displayScale: displayScale,
            fullPath: fullPath,
          );
        }
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.orange),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) =>
          const Center(child: Icon(Icons.error, color: Colors.red)),
    );
  }

  Widget _applyEffects(
    Widget image,
    BoardItem item, {
    required double currentWidth,
    required double currentHeight,
    required double displayScale,
    String? fullPath,
  }) {
    // Posterize first — B&W and blur wrap on top so they stack correctly
    if (item.isPosterized && _cachedUiImage != null) {
      final w = currentWidth * displayScale;
      final h = currentHeight * displayScale;
      final cachedImage = _cachedUiImage!;
      final fallback = image;
      image = FutureBuilder<ui.FragmentProgram>(
        future: _getPosterizeProgram(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return fallback;
          return CustomPaint(
            painter: _PosterizePainter(
              program: snapshot.data!,
              uiImage: cachedImage,
              levels: item.posterizationLevels,
            ),
            size: Size(w, h),
          );
        },
      );
    }

    if (item.isBlackAndWhite) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.299,
          0.587,
          0.114,
          0,
          0,
          0.299,
          0.587,
          0.114,
          0,
          0,
          0.299,
          0.587,
          0.114,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: image,
      );
    }

    if (item.isBlurred) {
      image = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: item.blurSigma,
          sigmaY: item.blurSigma,
          tileMode: TileMode.clamp,
        ),
        child: image,
      );
    }

    return image;
  }
}

class _PosterizePainter extends CustomPainter {
  final ui.FragmentProgram program;
  final ui.Image uiImage;
  final double levels;

  const _PosterizePainter({
    required this.program,
    required this.uiImage,
    required this.levels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Invert: slider 1 → 9 levels (subtle), slider 8 → 2 levels (extreme)
    final actualLevels = levels < 1.0 ? 0.0 : (10.0 - levels);
    final shader = program.fragmentShader()
      ..setFloat(0, actualLevels)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height)
      ..setImageSampler(0, uiImage);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_PosterizePainter old) =>
      old.levels != levels || old.uiImage != uiImage;
}
