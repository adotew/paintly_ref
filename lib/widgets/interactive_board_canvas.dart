import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';
import '../screens/canvas_screen.dart'; // For selectedItemIdProvider
import 'canvas_item.dart';
import 'grid_painter.dart';

class InteractiveBoardCanvas extends ConsumerStatefulWidget {
  final Board board;

  const InteractiveBoardCanvas({super.key, required this.board});

  @override
  ConsumerState<InteractiveBoardCanvas> createState() =>
      _InteractiveBoardCanvasState();
}

class _InteractiveBoardCanvasState
    extends ConsumerState<InteractiveBoardCanvas> {
  late TransformationController _transformationController;

  // Gesture state for the selected item
  Offset? _dragStartLocalPosition;
  Offset? _currentDragOffset;
  double _currentScaleDelta = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedItemId = ref.watch(selectedItemIdProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Center the canvas initially
        if (_transformationController.value.isIdentity()) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;
          final canvasSize = 7000.0;

          final x = -canvasSize / 2 + viewportWidth / 2;
          final y = -canvasSize / 2 + viewportHeight / 2;

          _transformationController.value = Matrix4.identity()..translate(x, y);
        }

        return Stack(
          children: [
            // Static Background with Grid
            Positioned.fill(
              child: Container(
                color: const Color.fromARGB(255, 30, 30, 30),
                child: CustomPaint(painter: GridPainter()),
              ),
            ),
            // Pannable Area
            InteractiveViewer(
              transformationController: _transformationController,
              // Limit the panning area so it's not infinite
              boundaryMargin: const EdgeInsets.all(500),
              minScale: 0.1,
              maxScale: 4.0,
              constrained: false, // Important for infinite canvas feeling
              // Disable canvas interaction when an item is selected
              panEnabled: selectedItemId == null,
              scaleEnabled: selectedItemId == null,
              child: Container(
                width: 7000,
                height: 7000,
                // Transparent so we see the static background
                color: Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    ref.read(selectedItemIdProvider.notifier).state = null;
                  },
                  onScaleStart: selectedItemId != null
                      ? (details) {
                          setState(() {
                            _dragStartLocalPosition = details.localFocalPoint;
                            _currentDragOffset = Offset.zero;
                            _currentScaleDelta = 1.0;
                          });
                        }
                      : null,
                  onScaleUpdate: selectedItemId != null
                      ? (details) {
                          if (_dragStartLocalPosition != null) {
                            setState(() {
                              // If using 2+ fingers, it's a pinch/zoom -> Update Scale Only
                              if (details.pointerCount > 1) {
                                _currentScaleDelta = details.scale;
                                // We intentionally do NOT update _currentDragOffset here
                                // to prevent the image from moving while resizing.
                              } else {
                                // If using 1 finger, it's a drag -> Update Position Only
                                _currentDragOffset =
                                    details.localFocalPoint -
                                    _dragStartLocalPosition!;
                              }
                            });
                          }
                        }
                      : null,
                  onScaleEnd: selectedItemId != null
                      ? (details) {
                          if (_dragStartLocalPosition != null) {
                            // Find the selected item
                            final itemIndex = widget.board.items.indexWhere(
                              (i) => i.id == selectedItemId,
                            );
                            if (itemIndex != -1) {
                              final item = widget.board.items[itemIndex];
                              final updatedItem = item.copyWith(
                                x: item.x + (_currentDragOffset?.dx ?? 0.0),
                                y: item.y + (_currentDragOffset?.dy ?? 0.0),
                                scale: item.scale * _currentScaleDelta,
                              );

                              final newItems = List<BoardItem>.from(
                                widget.board.items,
                              );
                              newItems[itemIndex] = updatedItem;

                              ref
                                  .read(boardListProvider.notifier)
                                  .updateBoard(
                                    widget.board.copyWith(items: newItems),
                                  );
                            }

                            setState(() {
                              _dragStartLocalPosition = null;
                              _currentDragOffset = null;
                              _currentScaleDelta = 1.0;
                            });
                          }
                        }
                      : null,
                  child: Stack(
                    children: [
                      // The Items
                      ...widget.board.items.map((item) {
                        final isSelected = item.id == selectedItemId;
                        return CanvasItem(
                          item: item,
                          // Only pass offsets if this is the selected item
                          additionalOffset:
                              isSelected ? _currentDragOffset : null,
                          additionalScale:
                              isSelected ? _currentScaleDelta : 1.0,
                          onSelect: () {
                            ref.read(selectedItemIdProvider.notifier).state =
                                item.id;

                            // Move the item to the end of the list (render on top)
                            // Only if it's not already the last one
                            if (widget.board.items.isNotEmpty &&
                                item.id != widget.board.items.last.id) {
                              final newItems = List<BoardItem>.from(
                                widget.board.items,
                              );
                              newItems.removeWhere((i) => i.id == item.id);
                              newItems.add(item);

                              ref
                                  .read(boardListProvider.notifier)
                                  .updateBoard(
                                    widget.board.copyWith(items: newItems),
                                  );
                            }
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

