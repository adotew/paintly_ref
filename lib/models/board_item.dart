import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'board_item.g.dart';

@HiveType(typeId: 1)
class BoardItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imageSource; // Lokaler Pfad oder URL

  @HiveField(2)
  final double x;

  @HiveField(3)
  final double y;

  @HiveField(4)
  final double scale;

  @HiveField(5)
  final double rotation; // In Radians

  @HiveField(6)
  final double width; // Ursprüngliche Breite (optional, nützlich für Aspect Ratio)

  @HiveField(7)
  final double height; // Ursprüngliche Höhe

  BoardItem({
    String? id,
    required this.imageSource,
    this.x = 0,
    this.y = 0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.width = 100.0,
    this.height = 100.0,
  }) : id = id ?? const Uuid().v4();

  BoardItem copyWith({
    String? imageSource,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    double? width,
    double? height,
  }) {
    return BoardItem(
      id: id,
      imageSource: imageSource ?? this.imageSource,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

