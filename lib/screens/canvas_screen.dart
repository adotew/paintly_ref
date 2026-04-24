import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';
import '../state/canvas_provider.dart';
import '../services/image_service.dart';
import '../widgets/interactive_board_canvas.dart';
import '../widgets/image_toolbar.dart';
import '../widgets/glass_tile.dart';

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
      body: Stack(
        children: [
          InteractiveBoardCanvas(board: board),

          // Back button — top left
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassTile(
                theWidth: 48,
                theHeight: 48,
                onPressed: () => Navigator.pop(context),
                theChild: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
            ),
          ),

          // Add image button — bottom right, hidden when item selected
          if (selectedItemId == null)
            Positioned(
              right: 16,
              bottom: 32,
              child: SafeArea(
                child: GlassTile(
                  theWidth: 48.0,
                  theHeight: 48.0,
                  onPressed: () => _pickAndAddImage(context, ref, board),
                  theChild: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),

          // Image Toolbar - appears when an image is selected
          ImageToolbar(isVisible: selectedItemId != null, boardId: board.id),
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
