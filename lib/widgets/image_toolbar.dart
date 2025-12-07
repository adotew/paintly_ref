import 'package:flutter/material.dart';

class ImageToolbar extends StatelessWidget {
  final bool isVisible;

  const ImageToolbar({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12.0,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToolbarButton(icon: Icons.format_bold, isActive: false),
                    _ToolbarButton(icon: Icons.format_italic, isActive: false),
                    _ToolbarButton(
                      icon: Icons.format_underlined,
                      isActive: false,
                    ),
                    _ToolbarButton(
                      icon: Icons.strikethrough_s,
                      isActive: false,
                    ),
                    _ToolbarButton(
                      icon: Icons.format_color_text,
                      isActive: false,
                    ),
                    _ToolbarButton(
                      icon: Icons.format_color_fill,
                      isActive: false,
                    ),
                    _ToolbarButton(icon: Icons.link, isActive: false),
                    _ToolbarButton(icon: Icons.image, isActive: true),
                    _ToolbarButton(icon: Icons.code, isActive: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final bool isActive;

  const _ToolbarButton({required this.icon, required this.isActive});

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  late bool _isToggled;

  @override
  void initState() {
    super.initState();
    _isToggled = widget.isActive;
  }

  @override
  void didUpdateWidget(_ToolbarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _isToggled = widget.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isToggled = !_isToggled;
          });
        },
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: _isToggled ? Colors.grey[700] : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Icon(
            widget.icon,
            size: 18.0,
            color: _isToggled ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
