import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_item.dart';
import '../state/board_provider.dart';
import '../state/canvas_provider.dart';
import 'glass_tile.dart';

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
    final boards = ref.watch(boardListProvider);

    BoardItem? item;
    if (selectedItemId != null) {
      final boardIndex = boards.indexWhere((b) => b.id == boardId);
      if (boardIndex != -1) {
        final items = boards[boardIndex].items;
        final itemIndex = items.indexWhere((i) => i.id == selectedItemId);
        if (itemIndex != -1) item = items[itemIndex];
      }
    }

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
            child: IntrinsicWidth(
              child: IntrinsicHeight(
                child: GlassTile(
                  borderRadius: 16.0,
                  theChild: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Posterization slider — expands when posterize is active
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: item != null && item.isPosterized
                        ? _PosterizationSlider(
                            levels: item.posterizationLevels,
                            onChanged: (v) => ref
                                .read(boardListProvider.notifier)
                                .setPosterizationLevels(boardId, item!.id, v),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Main button row
                  IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ToggleButton(
                          icon: Icons.flip,
                          isActive: item?.flipHorizontal ?? false,
                          tooltip: 'Flip',
                          onTap: () => ref
                              .read(boardListProvider.notifier)
                              .flipItemHorizontal(boardId, selectedItemId!),
                        ),
                        const SizedBox(width: 2),
                        _ToggleButton(
                          icon: Icons.invert_colors,
                          isActive: item?.isBlackAndWhite ?? false,
                          tooltip: 'B&W',
                          onTap: () => ref
                              .read(boardListProvider.notifier)
                              .toggleBlackAndWhite(boardId, selectedItemId!),
                        ),
                        const SizedBox(width: 2),
                        _ToggleButton(
                          icon: Icons.blur_on,
                          isActive: item?.isBlurred ?? false,
                          tooltip: 'Blur',
                          onTap: () => ref
                              .read(boardListProvider.notifier)
                              .toggleBlur(boardId, selectedItemId!),
                        ),
                        const SizedBox(width: 2),
                        _ToggleButton(
                          icon: Icons.gradient,
                          isActive: item?.isPosterized ?? false,
                          tooltip: 'Posterize',
                          onTap: () => ref
                              .read(boardListProvider.notifier)
                              .togglePosterize(boardId, selectedItemId!),
                        ),
                        const SizedBox(width: 8),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        _OverflowMenu(
                          onDelete: () =>
                              _onDelete(context, ref, selectedItemId),
                          onDuplicate: () =>
                              _onDuplicate(ref, selectedItemId),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _ToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            icon,
            size: 24.0,
            color: isActive ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}

class _PosterizationSlider extends StatelessWidget {
  final double levels;
  final ValueChanged<double> onChanged;

  const _PosterizationSlider({
    required this.levels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Levels: ${levels.round()}',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.grey[700],
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: levels,
                min: 0,
                max: 8,
                divisions: 8,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _OverflowMenu({required this.onDelete, required this.onDuplicate});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 24),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'delete') onDelete();
        if (value == 'duplicate') onDuplicate();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.content_copy, color: Colors.grey[300], size: 20),
              const SizedBox(width: 8),
              Text('Duplizieren',
                  style: TextStyle(color: Colors.grey[300])),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Löschen', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
