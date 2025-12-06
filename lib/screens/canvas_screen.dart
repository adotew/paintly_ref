import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';

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

class CanvasScreen extends ConsumerWidget {
  final String boardId;

  const CanvasScreen({super.key, required this.boardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We set the ID initially (once in the frame callback or better: we rely on the parameter)
    // Since we are in the build, it is better to use the provider directly or separate the logic.
    // Here is a clean approach: We filter the list directly.

    final board = ref
        .watch(boardListProvider)
        .firstWhere(
          (b) => b.id == boardId,
          orElse: () => Board(name: 'Error', id: 'error'), // Fallback
        );

    if (board.id == 'error') {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Board not found')),
      );
    }

    return Scaffold(
      body: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 4.0,
        child: Container(
          width: 5000, // Virtual Canvas Size
          height: 5000,
          color: const Color(0xFF222222), // Dark background for Canvas
          child: Stack(
            children: [
              // Center Marker (for orientation)
              const Center(
                child: Icon(Icons.add, color: Colors.white10, size: 50),
              ),

              // The Items
              ...board.items.map(
                (item) => _CanvasItem(
                  item: item,
                  onUpdate: (updatedItem) {
                    // Update Logic: We build a new item list
                    final newItems = board.items.map((i) {
                      return i.id == updatedItem.id ? updatedItem : i;
                    }).toList();

                    // And save the new board
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
    );
  }
}

class _CanvasItem extends StatelessWidget {
  final BoardItem item;
  final Function(BoardItem) onUpdate;

  const _CanvasItem({required this.item, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 2500 + item.x, // 2500 is the center of our 5000x5000 Canvas
      top: 2500 + item.y,
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
              border: Border.all(color: Colors.blueAccent, width: 2),
              color: Colors.white, // Placeholder Color
            ),
            child: _buildImageContent(),
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
