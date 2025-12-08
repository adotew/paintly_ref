import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';
import '../services/image_service.dart';
import '../widgets/interactive_board_canvas.dart';
import '../widgets/image_toolbar.dart';

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
        body: Stack(
          children: [
            const Center(child: Text('Board not found')),
            // Zurück-Button oben links
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
      );
    }

    final selectedItemId = ref.watch(selectedItemIdProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50.0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        leadingWidth: 112.0, // Double width for two buttons
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Implement pen/drawing functionality
              },
            ),
          ],
        ),
      ),
      floatingActionButton: selectedItemId == null
          ? FloatingActionButton(
              heroTag: 'add_image',
              onPressed: () => _pickAndAddImage(context, ref, board),
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: Stack(
        children: [
          InteractiveBoardCanvas(board: board),

          // Image Toolbar - appears when an image is selected
          ImageToolbar(isVisible: selectedItemId != null),
        ],
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
