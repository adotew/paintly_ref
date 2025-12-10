import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../state/board_provider.dart';
import '../models/board.dart';
import '../models/board_item.dart';
import 'canvas_screen.dart';

class BoardOverviewScreen extends ConsumerWidget {
  const BoardOverviewScreen({super.key});

  void _createBoard(BuildContext context, WidgetRef ref) {
    ref.read(boardListProvider.notifier).addBoard('Untitled').then((
      board,
    ) async {
      await Future.delayed(const Duration(milliseconds: 350));
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CanvasScreen(boardId: board.id)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boards = ref.watch(boardListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25.0, 30.0, 16.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/PaintlyRef.svg',
                    width: 150,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 0.0),
                    child: IconButton(
                      onPressed: () => _createBoard(context, ref),
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 43, 43, 43),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fixedSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(32.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // Tablet/Phone adjustment could go here
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: boards.length,
                itemBuilder: (context, index) {
                  final board = boards[index];
                  return _BoardCard(board: board);
                },
              ),
            ),
          ],
        ),
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            board.items.isEmpty
                ? Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.white24,
                    ),
                  )
                : _ImagePreviewGrid(items: board.items),
            // Gradient-Overlay unten mit Board-Namen
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        board.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${board.items.length} ${board.items.length == 1 ? 'Image' : 'Images'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
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

class _ImagePreviewGrid extends StatelessWidget {
  final List<BoardItem> items;

  const _ImagePreviewGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    // Wenn weniger als 4 Bilder: nur das letzte Bild anzeigen
    // Wenn 4 oder mehr Bilder: die letzten 4 anzeigen
    final itemsToShow = items.length < 4
        ? (items.isEmpty ? [] : [items.last])
        : items.sublist(items.length - 4);

    if (itemsToShow.isEmpty) {
      return Container(
        color: Colors.grey[800],
        child: const Icon(Icons.image, size: 48, color: Colors.white24),
      );
    }

    // Wenn nur 1 Bild vorhanden ist, zeige es in voller Größe
    if (itemsToShow.length == 1) {
      return FutureBuilder<String>(
        future: _getImagePath(itemsToShow[0].imageSource),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              File(snapshot.data!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.white24,
                  ),
                );
              },
            );
          }
          return Container(
            color: Colors.grey[800],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    // Für 2-4 Bilder: 2x2 Grid
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: itemsToShow.length,
      itemBuilder: (context, index) {
        return FutureBuilder<String>(
          future: _getImagePath(itemsToShow[index].imageSource),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.file(
                File(snapshot.data!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.broken_image,
                      size: 24,
                      color: Colors.white24,
                    ),
                  );
                },
              );
            }
            return Container(
              color: Colors.grey[800],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _getImagePath(String imageSource) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$imageSource';
  }
}
