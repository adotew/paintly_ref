import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';
import '../services/image_service.dart';
import '../widgets/interactive_board_canvas.dart';

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
      body: InteractiveBoardCanvas(board: board),
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
