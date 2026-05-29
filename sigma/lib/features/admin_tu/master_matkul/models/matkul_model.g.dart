// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matkul_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatkulModelAdapter extends TypeAdapter<MatkulModel> {
  @override
  final int typeId = 4;

  @override
  MatkulModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatkulModel(
      id: fields[0] as String,
      kodeMk: fields[1] as String,
      namaMatkul: fields[2] as String,
      programStudi: fields[3] as String,
      idProdi: fields[4] as String,
      sks: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MatkulModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kodeMk)
      ..writeByte(2)
      ..write(obj.namaMatkul)
      ..writeByte(3)
      ..write(obj.programStudi)
      ..writeByte(4)
      ..write(obj.idProdi)
      ..writeByte(5)
      ..write(obj.sks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatkulModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
