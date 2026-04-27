// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BoardAdapter extends TypeAdapter<Board> {
  @override
  final int typeId = 0;

  @override
  Board read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Board(
      id: fields[0] as String?,
      name: fields[1] as String,
      items: (fields[2] as List?)?.cast<BoardItem>(),
      createdAt: fields[3] as DateTime?,
      lastModified: fields[4] as DateTime?,
      viewportTranslateX: fields[5] as double?,
      viewportTranslateY: fields[6] as double?,
      viewportScale: fields[7] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Board obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastModified)
      ..writeByte(5)
      ..write(obj.viewportTranslateX)
      ..writeByte(6)
      ..write(obj.viewportTranslateY)
      ..writeByte(7)
      ..write(obj.viewportScale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
