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

class CanvasScreen extends ConsumerStatefulWidget {
  final String boardId;

  const CanvasScreen({super.key, required this.boardId});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  late TransformationController _transformationController;

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
                child: Container(
                  width: 7000,
                  height: 7000,
                  // Transparent so we see the static background
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      // The Items
                      ...board.items.map(
                        (item) => _CanvasItem(
                          item: item,
                          onUpdate: (updatedItem) {
                            final newItems = board.items.map((i) {
                              return i.id == updatedItem.id ? updatedItem : i;
                            }).toList();

                            ref
                                .read(boardListProvider.notifier)
                                .updateBoard(board.copyWith(items: newItems));
                          },
                        ),
                      ),
                    ],
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

class _CanvasItem extends StatelessWidget {
  final BoardItem item;
  final Function(BoardItem) onUpdate;

  const _CanvasItem({required this.item, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 3500 + item.x, // 2500 is the center of our 5000x5000 Canvas
      top: 3500 + item.y,
      child: Transform.rotate(
        angle: item.rotation,
        child: GestureDetector(
          onPanUpdate: (details) {
            onUpdate(
              item.copyWith(
                x: item.x + details.delta.dx,
                y: item.y + details.delta.dy,
              ),
            );
          },
          child: Container(
            width: item.width * item.scale,
            height: item.height * item.scale,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent, width: 3),
              borderRadius: BorderRadius.circular(21),
              color: Colors.white, // Placeholder Color
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildImageContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (item.imageSource.startsWith('http')) {
      return Image.network(item.imageSource, fit: BoxFit.cover);
    } else {
      final file = File(item.imageSource);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return const Center(child: Icon(Icons.broken_image, color: Colors.red));
    }
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
