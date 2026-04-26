// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementLocalModelAdapter
    extends TypeAdapter<AnnouncementLocalModel> {
  @override
  final int typeId = 2;

  @override
  AnnouncementLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnouncementLocalModel(
      id: fields[0] as String,
      judul: fields[1] as String,
      isi: fields[2] as String,
      kategori: fields[3] as String,
      tanggal: fields[4] as String,
      isImportant: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AnnouncementLocalModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.judul)
      ..writeByte(2)
      ..write(obj.isi)
      ..writeByte(3)
      ..write(obj.kategori)
      ..writeByte(4)
      ..write(obj.tanggal)
      ..writeByte(5)
      ..write(obj.isImportant);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementLocalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
