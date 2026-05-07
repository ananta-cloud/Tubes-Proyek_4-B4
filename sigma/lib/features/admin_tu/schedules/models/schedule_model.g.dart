// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleModelAdapter extends TypeAdapter<ScheduleModel> {
  @override
  final int typeId = 5;

  @override
  ScheduleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleModel(
      id: fields[0] as String,
      namaMatkul: fields[1] as String,
      namaDosen: fields[2] as String,
      hari: fields[3] as String,
      jamMulai: fields[4] as String,
      jamSelesai: fields[5] as String,
      ruangan: fields[6] as String,
      status: fields[7] as String,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.namaMatkul)
      ..writeByte(2)
      ..write(obj.namaDosen)
      ..writeByte(3)
      ..write(obj.hari)
      ..writeByte(4)
      ..write(obj.jamMulai)
      ..writeByte(5)
      ..write(obj.jamSelesai)
      ..writeByte(6)
      ..write(obj.ruangan)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
