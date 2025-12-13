import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';
import '../state/canvas_provider.dart';
import 'corner_handles.dart';

/// Custom painter for corner resize handles that wrap around corners

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

    // Scale border properties proportionally with the image size
    final baseBorderRadius = 21.0;
    final baseBorderWidth = 3.0;

    final scaledBorderRadius = baseBorderRadius * displayScale;
    final scaledBorderWidth = baseBorderWidth * displayScale;

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
                    borderRadius: BorderRadius.circular(scaledBorderRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(scaledBorderRadius),
                    child: _buildImageContent(ref),
                  ),
                ),
                // Border overlay (only when selected)
                if (isSelected)
                  Container(
                    width: item.width * displayScale,
                    height: item.height * displayScale,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blueAccent,
                        width: scaledBorderWidth,
                      ),
                      borderRadius: BorderRadius.circular(scaledBorderRadius),
                    ),
                  ),
                // Corner resize handles (only when selected)
                if (isSelected)
                  CustomPaint(
                    size: Size(
                      item.width * displayScale,
                      item.height * displayScale,
                    ),
                    painter: CornerHandlePainter(
                      handleLength: 12.0 * displayScale,
                      handleThickness: 8.0 * displayScale,
                      handleColor: Color.fromARGB(255, 235, 235, 235),
                      borderRadius: scaledBorderRadius,
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
