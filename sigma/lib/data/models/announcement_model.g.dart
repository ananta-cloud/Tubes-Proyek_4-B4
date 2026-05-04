// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementModelAdapter extends TypeAdapter<AnnouncementModel> {
  @override
  final int typeId = 2;

  @override
  AnnouncementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnouncementModel(
      id: fields[0] as String,
      judul: fields[1] as String,
      isi: fields[2] as String,
      targetAudience: fields[3] as String,
      namaPublisher: fields[4] as String,
      kategori: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
      isImportant: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AnnouncementModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.judul)
      ..writeByte(2)
      ..write(obj.isi)
      ..writeByte(3)
      ..write(obj.targetAudience)
      ..writeByte(4)
      ..write(obj.namaPublisher)
      ..writeByte(5)
      ..write(obj.kategori)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isImportant);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
