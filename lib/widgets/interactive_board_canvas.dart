import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';
import '../state/canvas_provider.dart';
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
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final matrix = _transformationController.value;
    ref.read(canvasScaleProvider.notifier).state = matrix.getMaxScaleOnAxis();
    ref.read(canvasTranslationProvider.notifier).state =
        Offset(matrix[12], matrix[13]);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      ref.read(boardListProvider.notifier).saveViewport(
        widget.board.id,
        matrix[12],
        matrix[13],
        matrix.getMaxScaleOnAxis(),
      );
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedItemId = ref.watch(selectedItemIdProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Restore saved viewport or center the canvas initially
        if (_transformationController.value.isIdentity()) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;
          const canvasSize = 7000.0;

          if (widget.board.viewportTranslateX != null) {
            final scale = widget.board.viewportScale!;
            final m = Matrix4.identity();
            m.setEntry(0, 0, scale);
            m.setEntry(1, 1, scale);
            m.setEntry(2, 2, scale);
            m[12] = widget.board.viewportTranslateX!;
            m[13] = widget.board.viewportTranslateY!;
            _transformationController.value = m;
          } else {
            final x = -canvasSize / 2 + viewportWidth / 2;
            final y = -canvasSize / 2 + viewportHeight / 2;
            _transformationController.value = Matrix4.identity()
              ..translateByDouble(x, y, 0.0, 1.0);
          }
        }

        return Stack(
          children: [
            // Static Background with Grid
            Positioned.fill(
              child: Container(
                color: const Color(0xFF252525),
                child: CustomPaint(painter: GridPainter()),
              ),
            ),
            // Pannable Area
            InteractiveViewer(
              transformationController: _transformationController,
              // Limit the panning area so it's not infinite
              minScale: 0.1,
              maxScale: 4.0,
              constrained: false, // Important for infinite canvas feeling
              panEnabled: true,
              scaleEnabled: true,
              child: Container(
                width: 7000,
                height: 7000,
                // Transparent so we see the static background
                color: Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    ref.read(selectedItemIdProvider.notifier).clear();
                  },
                  child: Stack(
                    children: [
                      // The Items
                      ...widget.board.items.map((item) {
                        return CanvasItem(
                          item: item,
                          board: widget.board,
                          onSelect: () {
                            ref
                                .read(selectedItemIdProvider.notifier)
                                .select(item.id);

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
