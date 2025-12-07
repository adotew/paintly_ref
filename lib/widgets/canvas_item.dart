import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';
import '../screens/canvas_screen.dart'; // For selectedItemIdProvider

class CanvasItem extends ConsumerWidget {
  final BoardItem item;
  final Offset? additionalOffset;
  final double additionalScale;
  final VoidCallback? onSelect;

  const CanvasItem({
    super.key,
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
      child: RepaintBoundary(
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
      ),
    );
  }

  Widget _buildImageContent(WidgetRef ref) {
    if (item.imageSource.startsWith('http')) {
      return Image.network(item.imageSource, fit: BoxFit.cover);
    }

    // Legacy Support: Falls der Pfad absolut ist (beginnt mit /), nutzen wir ihn direkt.
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
          return Image.file(
            file,
            fit: BoxFit.cover,
            cacheWidth: 1000, // RAM-Optimierung
          );
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

