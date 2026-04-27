import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'board_item.dart';

part 'board.g.dart';

@HiveType(typeId: 0)
class Board {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<BoardItem> items;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime lastModified;

  @HiveField(5)
  final double? viewportTranslateX;

  @HiveField(6)
  final double? viewportTranslateY;

  @HiveField(7)
  final double? viewportScale;

  Board({
    String? id,
    required this.name,
    List<BoardItem>? items,
    DateTime? createdAt,
    DateTime? lastModified,
    this.viewportTranslateX,
    this.viewportTranslateY,
    this.viewportScale,
  }) : id = id ?? const Uuid().v4(),
       items = items ?? const [],
       createdAt = createdAt ?? DateTime.now(),
       lastModified = lastModified ?? DateTime.now();

  Board copyWith({
    String? name,
    List<BoardItem>? items,
    DateTime? lastModified,
    double? viewportTranslateX,
    double? viewportTranslateY,
    double? viewportScale,
  }) {
    return Board(
      id: id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
      viewportTranslateX: viewportTranslateX ?? this.viewportTranslateX,
      viewportTranslateY: viewportTranslateY ?? this.viewportTranslateY,
      viewportScale: viewportScale ?? this.viewportScale,
    );
  }
}
