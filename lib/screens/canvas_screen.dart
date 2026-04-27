import 'dart:async';
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
  bool _uiVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _hideTimer?.cancel();
    if (!_uiVisible) setState(() => _uiVisible = true);
    _hideTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _uiVisible = false);
    });
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
      body: Listener(
        onPointerDown: (_) => _resetTimer(),
        child: Stack(
        children: [
          InteractiveBoardCanvas(board: board),

          // Back button — top left, fades when item selected or UI hidden
          AnimatedOpacity(
            opacity: selectedItemId == null && _uiVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: selectedItemId != null || !_uiVisible,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GlassTile(
                    theWidth: 48,
                    theHeight: 48,
                    onPressed: () => Navigator.pop(context),
                    theChild: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Add image button — bottom right, fades when item selected or UI hidden
          Positioned(
            right: 16,
            bottom: 16,
            child: AnimatedOpacity(
              opacity: selectedItemId == null && _uiVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: selectedItemId != null || !_uiVisible,
                child: SafeArea(
                  child: GlassTile(
                    theWidth: 48.0,
                    theHeight: 48.0,
                    onPressed: () => _pickAndAddImage(context, ref, board),
                    theChild: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // Image Toolbar - appears when an image is selected
          ImageToolbar(isVisible: selectedItemId != null, boardId: board.id),
        ],
        ),
      ),
    );
  }

  Future<void> _pickAndAddImage(
    BuildContext context,
    WidgetRef ref,
    Board board,
  ) async {
    try {
      final scale = ref.read(canvasScaleProvider);
      final translation = ref.read(canvasTranslationProvider);
      final screenSize = MediaQuery.of(context).size;
      final cx = (screenSize.width / 2 - translation.dx) / scale;
      final cy = (screenSize.height / 2 - translation.dy) / scale;
      final center = Offset(cx - 3500 - 150, cy - 3500 - 150);

      final imageService = ImageService();
      final newItems = await imageService.pickAndProcessImages(center: center);

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
