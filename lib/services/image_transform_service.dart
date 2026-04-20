import 'package:flutter/material.dart';

/// Enum für die 4 Resize-Handles an den Ecken
enum ResizeHandle { topLeft, topRight, bottomLeft, bottomRight }

/// Ergebnis einer Resize-Operation
class ResizeResult {
  final double x;
  final double y;
  final double width;
  final double height;

  const ResizeResult({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Service für Image-Transform-Operationen (Drag, Resize)
/// Alle Methoden sind statisch - kein State, nur pure Funktionen
class ImageTransformService {
  ImageTransformService._(); // Private constructor - nur statische Methoden

  /// Mindestgröße für Items beim Resize
  static const double minSize = 50.0;

  /// Berechnet die neue Position nach einem Drag
  static Offset calculateDragPosition({
    required double startX,
    required double startY,
    required Offset dragDelta,
  }) {
    return Offset(startX + dragDelta.dx, startY + dragDelta.dy);
  }

  /// Berechnet welcher ResizeHandle an einer Position getroffen wurde
  /// Gibt null zurück wenn kein Handle getroffen wurde
  static ResizeHandle? hitTestHandle({
    required Offset localPosition,
    required double itemWidth,
    required double itemHeight,
    required double hitAreaSize,
  }) {
    final hitArea = hitAreaSize;

    // Top-Left
    if (localPosition.dx < hitArea && localPosition.dy < hitArea) {
      return ResizeHandle.topLeft;
    }

    // Top-Right
    if (localPosition.dx > itemWidth - hitArea && localPosition.dy < hitArea) {
      return ResizeHandle.topRight;
    }

    // Bottom-Left
    if (localPosition.dx < hitArea && localPosition.dy > itemHeight - hitArea) {
      return ResizeHandle.bottomLeft;
    }

    // Bottom-Right
    if (localPosition.dx > itemWidth - hitArea &&
        localPosition.dy > itemHeight - hitArea) {
      return ResizeHandle.bottomRight;
    }

    return null;
  }

  /// Berechnet die neue Größe und Position nach einem Resize
  /// Behält das Aspect Ratio bei (Standard-Verhalten wie in Figma)
  static ResizeResult calculateResize({
    required ResizeHandle handle,
    required double startX,
    required double startY,
    required double startWidth,
    required double startHeight,
    required Offset delta,
    bool maintainAspectRatio = true,
  }) {
    double newX = startX;
    double newY = startY;
    double newWidth = startWidth;
    double newHeight = startHeight;

    final aspectRatio = startWidth / startHeight;

    switch (handle) {
      case ResizeHandle.bottomRight:
        // Einfachster Fall: Position bleibt, nur Größe ändert sich
        if (maintainAspectRatio) {
          // Nutze die größere Änderung für proportionales Resize
          final avgDelta = (delta.dx + delta.dy) / 2;
          newWidth = (startWidth + avgDelta).clamp(minSize, double.infinity);
          newHeight = newWidth / aspectRatio;
        } else {
          newWidth = (startWidth + delta.dx).clamp(minSize, double.infinity);
          newHeight = (startHeight + delta.dy).clamp(minSize, double.infinity);
        }
        break;

      case ResizeHandle.bottomLeft:
        if (maintainAspectRatio) {
          final avgDelta = (-delta.dx + delta.dy) / 2;
          newWidth = (startWidth + avgDelta).clamp(minSize, double.infinity);
          newHeight = newWidth / aspectRatio;
          newX = startX + startWidth - newWidth;
        } else {
          newWidth = (startWidth - delta.dx).clamp(minSize, double.infinity);
          newHeight = (startHeight + delta.dy).clamp(minSize, double.infinity);
          newX = startX + startWidth - newWidth;
        }
        break;

      case ResizeHandle.topRight:
        if (maintainAspectRatio) {
          final avgDelta = (delta.dx - delta.dy) / 2;
          newWidth = (startWidth + avgDelta).clamp(minSize, double.infinity);
          newHeight = newWidth / aspectRatio;
          newY = startY + startHeight - newHeight;
        } else {
          newWidth = (startWidth + delta.dx).clamp(minSize, double.infinity);
          newHeight = (startHeight - delta.dy).clamp(minSize, double.infinity);
          newY = startY + startHeight - newHeight;
        }
        break;

      case ResizeHandle.topLeft:
        if (maintainAspectRatio) {
          final avgDelta = (-delta.dx - delta.dy) / 2;
          newWidth = (startWidth + avgDelta).clamp(minSize, double.infinity);
          newHeight = newWidth / aspectRatio;
          newX = startX + startWidth - newWidth;
          newY = startY + startHeight - newHeight;
        } else {
          newWidth = (startWidth - delta.dx).clamp(minSize, double.infinity);
          newHeight = (startHeight - delta.dy).clamp(minSize, double.infinity);
          newX = startX + startWidth - newWidth;
          newY = startY + startHeight - newHeight;
        }
        break;
    }

    // Sicherstellen dass Mindestgröße eingehalten wird
    if (newHeight < minSize) {
      newHeight = minSize;
      newWidth = minSize * aspectRatio;
    }

    return ResizeResult(x: newX, y: newY, width: newWidth, height: newHeight);
  }

  /// Berechnet die Hit-Area-Größe basierend auf dem aktuellen Scale.
  /// Floor liegt bei 44pt (Apple HIG Minimum für Touch-Targets), damit
  /// Corner-Handles auf iPad zuverlässig greifbar bleiben.
  static double getHitAreaSize(double scale) {
    return (44.0 * scale).clamp(44.0, 72.0);
  }
}
