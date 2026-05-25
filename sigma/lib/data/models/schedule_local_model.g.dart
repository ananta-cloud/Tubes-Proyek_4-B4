// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleLocalModelAdapter extends TypeAdapter<ScheduleLocalModel> {
  @override
  final int typeId = 1;

  @override
  ScheduleLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleLocalModel(
      id: fields[0] as String,
      namaMk: fields[1] as String,
      hari: fields[2] as String,
      jamMulai: fields[3] as String,
      jamSelesai: fields[4] as String,
      ruangan: fields[5] as String,
      dosen: fields[6] as String,
      status: fields[7] as String,
      tipe: fields[8] as String,
      kodeMk: fields[9] as String,
      idMk: fields[10] as String,
      idProdi: fields[11] as String,
      idJurusan: fields[12] as String,
      idPeriode: fields[13] as String,
      updatedAt: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleLocalModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.namaMk)
      ..writeByte(2)
      ..write(obj.hari)
      ..writeByte(3)
      ..write(obj.jamMulai)
      ..writeByte(4)
      ..write(obj.jamSelesai)
      ..writeByte(5)
      ..write(obj.ruangan)
      ..writeByte(6)
      ..write(obj.dosen)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.tipe)
      ..writeByte(9)
      ..write(obj.kodeMk)
      ..writeByte(10)
      ..write(obj.idMk)
      ..writeByte(11)
      ..write(obj.idProdi)
      ..writeByte(12)
      ..write(obj.idJurusan)
      ..writeByte(13)
      ..write(obj.idPeriode)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleLocalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
