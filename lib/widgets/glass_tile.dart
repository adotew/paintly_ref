import 'package:flutter/material.dart';
import 'dart:ui';

class GlassTile extends StatelessWidget {
  const GlassTile({
    Key? key,
    required this.theChild,
    this.theWidth,
    this.theHeight,
    this.onPressed,
    this.isActive = false,
    this.borderRadius = 12.0,
  }) : super(key: key);

  final Widget theChild;
  final double? theWidth;
  final double? theHeight;
  final VoidCallback? onPressed;
  final bool isActive;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: theWidth,
          height: theHeight,
          color: Colors.transparent,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                child: Container(),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withOpacity(isActive ? 0.35 : 0.13),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(isActive ? 0.28 : 0.15),
                      Colors.white.withOpacity(isActive ? 0.12 : 0.05),
                    ],
                  ),
                ),
              ),
              Center(child: theChild),
            ],
          ),
        ),
      ),
    );
  }
}
