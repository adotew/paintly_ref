import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/board_provider.dart';
import '../state/canvas_provider.dart';

class ImageToolbar extends ConsumerWidget {
  final bool isVisible;
  final String boardId;

  const ImageToolbar({
    super.key,
    required this.isVisible,
    required this.boardId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItemId = ref.watch(selectedItemIdProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      bottom: isVisible ? 0 : -200,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12.0,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Löschen
                      _ToolbarButton(
                        icon: Icons.delete,
                        onTap: () => _onDelete(context, ref, selectedItemId),
                        tooltip: 'Löschen',
                      ),
                      const SizedBox(width: 4),
                      // Duplizieren
                      _ToolbarButton(
                        icon: Icons.content_copy,
                        onTap: () => _onDuplicate(ref, selectedItemId),
                        tooltip: 'Duplizieren',
                      ),
                      const SizedBox(width: 4),
                      // Flip horizontal
                      _ToolbarButton(
                        icon: Icons.flip,
                        onTap: () => _onFlipHorizontal(ref, selectedItemId),
                        tooltip: 'Horizontal spiegeln',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onDelete(BuildContext context, WidgetRef ref, String? itemId) {
    if (itemId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bild löschen?'),
        content: const Text('Möchten Sie dieses Bild wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(boardListProvider.notifier)
                  .deleteItemFromBoard(boardId, itemId);
              ref.read(selectedItemIdProvider.notifier).clear();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _onDuplicate(WidgetRef ref, String? itemId) {
    if (itemId == null) return;
    ref.read(boardListProvider.notifier).duplicateItem(boardId, itemId);
  }

  void _onFlipHorizontal(WidgetRef ref, String? itemId) {
    if (itemId == null) return;
    ref.read(boardListProvider.notifier).flipItemHorizontal(boardId, itemId);
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const _ToolbarButton({required this.icon, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsetsGeometry.fromLTRB(2.0, 0.0, 2.0, 0.0),
            child: Container(
              padding: const EdgeInsetsGeometry.fromLTRB(
                12.0,
                12.0,
                12.0,
                12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, size: 24.0, color: Colors.grey[300]),
            ),
          ),
        ),
      ),
    );
  }
}
