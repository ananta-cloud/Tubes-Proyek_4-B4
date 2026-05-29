// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 3;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      idUser: fields[1] as String,
      namaTugas: fields[2] as String,
      deskripsi: fields[3] as String?,
      kodeMk: fields[4] as String?,
      namaMkSnapshot: fields[5] as String?,
      deadline: fields[6] as DateTime,
      status: fields[7] as String,
      isSynced: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      lampiran: (fields[11] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, String>())
          ?.toList(),
      targetKelas: (fields[12] as List?)?.cast<String>(),
      namaDosen: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.idUser)
      ..writeByte(2)
      ..write(obj.namaTugas)
      ..writeByte(3)
      ..write(obj.deskripsi)
      ..writeByte(4)
      ..write(obj.kodeMk)
      ..writeByte(5)
      ..write(obj.namaMkSnapshot)
      ..writeByte(6)
      ..write(obj.deadline)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.isSynced)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.lampiran)
      ..writeByte(12)
      ..write(obj.targetKelas)
      ..writeByte(13)
      ..write(obj.namaDosen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
