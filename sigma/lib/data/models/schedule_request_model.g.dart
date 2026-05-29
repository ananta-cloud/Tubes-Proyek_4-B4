// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_request_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DetailPerubahanAdapter extends TypeAdapter<DetailPerubahan> {
  @override
  final int typeId = 3;

  @override
  DetailPerubahan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DetailPerubahan(
      hariBaru: fields[0] as String?,
      tanggalBaru: fields[1] as DateTime?,
      jamMulaiBaru: fields[2] as String?,
      jamSelesaiBaru: fields[3] as String?,
      ruanganBaru: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DetailPerubahan obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.hariBaru)
      ..writeByte(1)
      ..write(obj.tanggalBaru)
      ..writeByte(2)
      ..write(obj.jamMulaiBaru)
      ..writeByte(3)
      ..write(obj.jamSelesaiBaru)
      ..writeByte(4)
      ..write(obj.ruanganBaru);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetailPerubahanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScheduleRequestModelAdapter extends TypeAdapter<ScheduleRequestModel> {
  @override
  final int typeId = 4;

  @override
  ScheduleRequestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleRequestModel(
      id: fields[0] as String,
      idSchedule: fields[1] as String,
      idDosen: fields[2] as String,
      namaDosen: fields[3] as String,
      tipeRequest: fields[4] as String,
      detailPerubahan: fields[5] as DetailPerubahan,
      alasan: fields[6] as String,
      status: fields[7] as String,
      offlineId: fields[8] as String?,
      catatanAdmin: fields[9] as String?,
      idProcessor: fields[10] as String?,
      isLate: fields[11] as bool?,
      createdAt: fields[12] as DateTime?,
      updatedAt: fields[13] as DateTime?,
      namaMk: fields[14] as String?,
      kodeMk: fields[15] as String?,
      hariJadwal: fields[16] as String?,
      jamMulaiJadwal: fields[17] as String?,
      jamSelesaiJadwal: fields[18] as String?,
      ruanganJadwal: fields[19] as String?,
      kelas: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleRequestModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.idSchedule)
      ..writeByte(2)
      ..write(obj.idDosen)
      ..writeByte(3)
      ..write(obj.namaDosen)
      ..writeByte(4)
      ..write(obj.tipeRequest)
      ..writeByte(5)
      ..write(obj.detailPerubahan)
      ..writeByte(6)
      ..write(obj.alasan)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.offlineId)
      ..writeByte(9)
      ..write(obj.catatanAdmin)
      ..writeByte(10)
      ..write(obj.idProcessor)
      ..writeByte(11)
      ..write(obj.isLate)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.namaMk)
      ..writeByte(15)
      ..write(obj.kodeMk)
      ..writeByte(16)
      ..write(obj.hariJadwal)
      ..writeByte(17)
      ..write(obj.jamMulaiJadwal)
      ..writeByte(18)
      ..write(obj.jamSelesaiJadwal)
      ..writeByte(19)
      ..write(obj.ruanganJadwal)
      ..writeByte(20)
      ..write(obj.kelas);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleRequestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
