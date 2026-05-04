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
<<<<<<<< HEAD:sigma/lib/data/models/announcement_model.g.dart
      namaPublisher: fields[4] as String,
      kategori: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
      isImportant: fields[7] as bool,
========
      idPublisher: fields[4] as String,
      namaPublisher: fields[5] as String,
      rolePublisher: fields[6] as String,
      idProdi: fields[7] as String?,
      idJurusan: fields[8] as String?,
      targetAngkatan: (fields[9] as List?)?.cast<String>(),
      kategori: (fields[10] as List).cast<String>(),
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      tingkatKepentingan: fields[13] as String,
>>>>>>>> nazriel:sigma/lib/features/admin_tu/announcements/models/announcement_model.g.dart
    );
  }

  @override
  void write(BinaryWriter writer, AnnouncementModel obj) {
    writer
<<<<<<<< HEAD:sigma/lib/data/models/announcement_model.g.dart
      ..writeByte(8)
========
      ..writeByte(14)
>>>>>>>> nazriel:sigma/lib/features/admin_tu/announcements/models/announcement_model.g.dart
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.judul)
      ..writeByte(2)
      ..write(obj.isi)
      ..writeByte(3)
      ..write(obj.targetAudience)
      ..writeByte(4)
      ..write(obj.idPublisher)
      ..writeByte(5)
      ..write(obj.namaPublisher)
      ..writeByte(6)
<<<<<<<< HEAD:sigma/lib/data/models/announcement_model.g.dart
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isImportant);
========
      ..write(obj.rolePublisher)
      ..writeByte(7)
      ..write(obj.idProdi)
      ..writeByte(8)
      ..write(obj.idJurusan)
      ..writeByte(9)
      ..write(obj.targetAngkatan)
      ..writeByte(10)
      ..write(obj.kategori)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.tingkatKepentingan);
>>>>>>>> nazriel:sigma/lib/features/admin_tu/announcements/models/announcement_model.g.dart
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