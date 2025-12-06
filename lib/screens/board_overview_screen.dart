import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/board_provider.dart';
import '../models/board.dart';
import 'canvas_screen.dart';

class BoardOverviewScreen extends ConsumerWidget {
  const BoardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boards = ref.watch(boardListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PaintlyRef Boards')),
      body: boards.isEmpty
          ? const Center(
              child: Text(
                'No boards available.\nCreate your first moodboard!',
                textAlign: TextAlign.center,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Tablet/Phone adjustment could go here
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: boards.length,
              itemBuilder: (context, index) {
                final board = boards[index];
                return _BoardCard(board: board);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Board'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Board Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(boardListProvider.notifier).addBoard(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _BoardCard extends ConsumerWidget {
  final Board board;

  const _BoardCard({required this.board});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CanvasScreen(boardId: board.id)),
          );
        },
        onLongPress: () {
          _showDeleteDialog(context, ref, board);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[800],
                child: const Icon(Icons.image, size: 48, color: Colors.white24),
                // Later: Preview of the first image
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    board.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${board.items.length} Items',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Board board) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Board?'),
        content: Text('Do you really want to delete "${board.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(boardListProvider.notifier).deleteBoard(board.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
