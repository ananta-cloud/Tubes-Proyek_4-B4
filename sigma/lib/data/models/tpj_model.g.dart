// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tpj_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimPenjadwalanModelAdapter extends TypeAdapter<TimPenjadwalanModel> {
  @override
  final int typeId = 8;

  @override
  TimPenjadwalanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimPenjadwalanModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      nama: fields[2] as String,
      idJurusan: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TimPenjadwalanModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.nama)
      ..writeByte(3)
      ..write(obj.idJurusan)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimPenjadwalanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
