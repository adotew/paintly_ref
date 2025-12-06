// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BoardItemAdapter extends TypeAdapter<BoardItem> {
  @override
  final int typeId = 1;

  @override
  BoardItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoardItem(
      id: fields[0] as String?,
      imageSource: fields[1] as String,
      x: fields[2] as double,
      y: fields[3] as double,
      scale: fields[4] as double,
      rotation: fields[5] as double,
      width: fields[6] as double,
      height: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BoardItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageSource)
      ..writeByte(2)
      ..write(obj.x)
      ..writeByte(3)
      ..write(obj.y)
      ..writeByte(4)
      ..write(obj.scale)
      ..writeByte(5)
      ..write(obj.rotation)
      ..writeByte(6)
      ..write(obj.width)
      ..writeByte(7)
      ..write(obj.height);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
