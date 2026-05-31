// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pengajaran_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PengajaranModelAdapter extends TypeAdapter<PengajaranModel> {
  @override
  final int typeId = 9;

  @override
  PengajaranModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PengajaranModel(
      id: fields[0] as String,
      kodeDosen: fields[1] as String,
      kodeMk: fields[2] as String,
      namaMk: fields[3] as String,
      targetKelas: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PengajaranModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kodeDosen)
      ..writeByte(2)
      ..write(obj.kodeMk)
      ..writeByte(3)
      ..write(obj.namaMk)
      ..writeByte(4)
      ..write(obj.targetKelas);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PengajaranModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
