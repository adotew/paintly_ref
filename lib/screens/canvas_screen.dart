import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';
import '../services/image_service.dart';

// Provider for the currently selected board (set via .family or override)
// For simplicity, we use a StateProvider here that holds the ID.
final activeBoardIdProvider = StateProvider<String?>((ref) => null);

// A provider that delivers the current Board object based on the ID
final activeBoardProvider = Provider<Board?>((ref) {
  final id = ref.watch(activeBoardIdProvider);
  final boards = ref.watch(boardListProvider);
  if (id == null) return null;
  try {
    return boards.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
});

final selectedItemIdProvider = StateProvider<String?>((ref) => null);

class CanvasScreen extends ConsumerStatefulWidget {
  final String boardId;

  const CanvasScreen({super.key, required this.boardId});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
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
    final board = ref
        .watch(boardListProvider)
        .firstWhere(
          (b) => b.id == widget.boardId,
          orElse: () => Board(name: 'Error', id: 'error'), // Fallback
        );

    if (board.id == 'error') {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Board not found')),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_image',
        onPressed: () => _pickAndAddImage(context, ref, board),
        child: const Icon(Icons.add),
        backgroundColor: Colors.grey[800],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Center the canvas initially
          if (_transformationController.value.isIdentity()) {
            final viewportWidth = constraints.maxWidth;
            final viewportHeight = constraints.maxHeight;
            final canvasSize = 7000.0;

            final x = -canvasSize / 2 + viewportWidth / 2;
            final y = -canvasSize / 2 + viewportHeight / 2;

            _transformationController.value = Matrix4.identity()
              ..translate(x, y);
          }

          return Stack(
            children: [
              // Static Background with Grid
              Positioned.fill(
                child: Container(
                  color: const Color.fromARGB(255, 30, 30, 30),
                  child: CustomPaint(painter: _GridPainter()),
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
                              final itemIndex = board.items.indexWhere(
                                (i) => i.id == selectedItemId,
                              );
                              if (itemIndex != -1) {
                                final item = board.items[itemIndex];
                                final updatedItem = item.copyWith(
                                  x: item.x + (_currentDragOffset?.dx ?? 0.0),
                                  y: item.y + (_currentDragOffset?.dy ?? 0.0),
                                  scale: item.scale * _currentScaleDelta,
                                );

                                final newItems = List<BoardItem>.from(
                                  board.items,
                                );
                                newItems[itemIndex] = updatedItem;

                                ref
                                    .read(boardListProvider.notifier)
                                    .updateBoard(
                                      board.copyWith(items: newItems),
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
                        ...board.items.map((item) {
                          final isSelected = item.id == selectedItemId;
                          return _CanvasItem(
                            item: item,
                            // Only pass offsets if this is the selected item
                            additionalOffset: isSelected
                                ? _currentDragOffset
                                : null,
                            additionalScale: isSelected
                                ? _currentScaleDelta
                                : 1.0,
                            onSelect: () {
                              ref.read(selectedItemIdProvider.notifier).state =
                                  item.id;

                              // Move the item to the end of the list (render on top)
                              // Only if it's not already the last one
                              if (board.items.isNotEmpty &&
                                  item.id != board.items.last.id) {
                                final newItems = List<BoardItem>.from(
                                  board.items,
                                );
                                newItems.removeWhere((i) => i.id == item.id);
                                newItems.add(item);

                                ref
                                    .read(boardListProvider.notifier)
                                    .updateBoard(
                                      board.copyWith(items: newItems),
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
      ),
    );
  }

  Future<void> _pickAndAddImage(
    BuildContext context,
    WidgetRef ref,
    Board board,
  ) async {
    try {
      final imageService = ImageService();
      final newItems = await imageService.pickAndProcessImages();

      if (newItems.isNotEmpty) {
        final updatedItems = List<BoardItem>.from(board.items)
          ..addAll(newItems);
        ref
            .read(boardListProvider.notifier)
            .updateBoard(board.copyWith(items: updatedItems));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _CanvasItem extends ConsumerWidget {
  final BoardItem item;
  final Offset? additionalOffset;
  final double additionalScale;
  final VoidCallback? onSelect;

  const _CanvasItem({
    required this.item,
    this.additionalOffset,
    this.additionalScale = 1.0,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(selectedItemIdProvider) == item.id;

    final displayX = item.x + (additionalOffset?.dx ?? 0.0);
    final displayY = item.y + (additionalOffset?.dy ?? 0.0);
    final displayScale = item.scale * additionalScale;

    return Positioned(
      left: 3500 + displayX,
      top: 3500 + displayY,
      child: GestureDetector(
        onTap: onSelect,
        child: Transform.rotate(
          angle: item.rotation,
          child: Stack(
            children: [
              // Image container (full size, no border)
              Container(
                width: item.width * displayScale,
                height: item.height * displayScale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _buildImageContent(ref),
                ),
              ),
              // Border overlay (only when selected)
              if (isSelected)
                Container(
                  width: item.width * displayScale,
                  height: item.height * displayScale,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 3),
                    borderRadius: BorderRadius.circular(21),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(WidgetRef ref) {
    if (item.imageSource.startsWith('http')) {
      return Image.network(item.imageSource, fit: BoxFit.cover);
    }

    // Legacy Support: Falls der Pfad absolut ist (beginnt mit /), nutzen wir ihn direkt.
    // (Dies deckt alte Items ab, bevor wir auf Dateinamen umgestiegen sind)
    if (item.imageSource.startsWith('/') ||
        (Platform.isWindows && item.imageSource.contains(':'))) {
      final file = File(item.imageSource);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return const Center(child: Icon(Icons.broken_image, color: Colors.red));
    }

    // Relative Pfade (neu): Wir müssen das Dokumenten-Verzeichnis holen
    final appDirAsync = ref.watch(appDocumentsDirectoryProvider);

    return appDirAsync.when(
      data: (dir) {
        final fullPath = '${dir.path}/${item.imageSource}';
        final file = File(fullPath);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const step = 22.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
