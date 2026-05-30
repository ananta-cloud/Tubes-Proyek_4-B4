import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box, State, Center;

import '../../../core/network/mongo_database.dart';
import '../models/schedule_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Nama box Hive yang dipakai untuk lookup offline
//    'admin_matkul' → Box<MatkulModel>  (sudah ada di main.dart)
//    'dosen_cache'  → Box<Map>          (cache sederhana kode→nama, lihat
//                                        DosenCacheService di bawah)
// ─────────────────────────────────────────────────────────────────────────────
const _kBoxMatkul = 'admin_matkul';
const _kBoxDosenCache = 'dosen_cache';

// ─────────────────────────────────────────────────────────────────────────────
//  ScheduleExcelParser
//
//  Strategi lookup nama (offline-first):
//    1. Cari di Hive lokal dulu  → tidak butuh internet sama sekali
//    2. Kode yang tidak ketemu & online → query MongoDB
//    3. Masih tidak ketemu       → kode sebagai placeholder,
//                                  needsEnrichment = true
// ─────────────────────────────────────────────────────────────────────────────
class ScheduleExcelParser {
  ScheduleExcelParser._();

  static Future<List<ScheduleModel>> parse(String filePath) async {
    final rawRows = await _readExcel(filePath);

    if (rawRows.isEmpty) {
      throw Exception(
        'Tidak ada data yang berhasil diparsing. '
        'Pastikan format kolom sesuai: HARI, JAM KE, KODE MK, '
        'KODE DOSEN, RUANGAN, KELAS.',
      );
    }

    final kodeMkSet = rawRows
        .map((r) => r.kodeMk)
        .where((k) => k.isNotEmpty)
        .toSet();

    final kodeDosenSet = <String>{};
    for (final r in rawRows) {
      for (final k in r.kodeDosen.split(';')) {
        final t = k.trim();
        if (t.isNotEmpty) kodeDosenSet.add(t);
      }
    }

    final namaMkMap = await _lookupNamaMk(kodeMkSet);
    final namaDosenMap = await _lookupNamaDosen(kodeDosenSet);

    final missedMk = kodeMkSet.where((k) => !namaMkMap.containsKey(k)).toSet();
    final missedDosen = kodeDosenSet
        .where((k) => !namaDosenMap.containsKey(k))
        .toSet();
    final needsEnrich = missedMk.isNotEmpty || missedDosen.isNotEmpty;

    if (needsEnrich) {
      debugPrint(
        '   Beberapa kode tidak ditemukan:\n'
        '   MK: $missedMk\n'
        '   Dosen: $missedDosen\n'
        '   → Akan di-enrich saat online.',
      );
    }

    return _mergeRows(rawRows, namaMkMap, namaDosenMap, needsEnrich);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Step 1 — Baca Excel (tidak berubah dari versi sebelumnya)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<_RawRow>> _readExcel(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excelFile = excel_pkg.Excel.decodeBytes(bytes);
    final rawRows = <_RawRow>[];

    String semester = 'GENAP';
    String tahunAkademik = '2025/2026';

    for (final sheetName in excelFile.tables.keys) {
      final sheet = excelFile.tables[sheetName];
      if (sheet == null) continue;
      final rows = sheet.rows;
      if (rows.isEmpty) continue;

      int headerRowIndex = -1;
      for (int i = 0; i < rows.length && i < 20; i++) {
        final rowText = rows[i]
            .map((c) => c?.value?.toString().toUpperCase() ?? '')
            .join(' ');
        if (rowText.contains('HARI') && rowText.contains('KELAS')) {
          headerRowIndex = i;
          break;
        }
        if (rowText.contains('GENAP')) semester = 'GENAP';
        if (rowText.contains('GANJIL')) semester = 'GANJIL';
        final m = RegExp(r'(\d{4}/\d{4})').firstMatch(rowText);
        if (m != null) tahunAkademik = m.group(1)!;
      }
      if (headerRowIndex == -1) continue;

      final headerRow = rows[headerRowIndex];
      final colMap = <String, int>{};
      for (int j = 0; j < headerRow.length; j++) {
        final val = headerRow[j]?.value?.toString().trim().toUpperCase() ?? '';
        if (val.isNotEmpty) colMap[val] = j;
      }

      final colHari = _findCol(colMap, ['HARI']);
      final colJamKe = _findCol(colMap, ['JAM KE', 'JAM_KE', 'JAMKE']);
      final colWaktu = _findCol(colMap, ['WAKTU']);
      final colKodeMk = _findCol(colMap, ['KODE MK', 'KODE_MK', 'KODEMK']);
      final colTePr = _findCol(colMap, ['TE/PR', 'TEPR', 'TE_PR']);
      final colKodeDosen = _findCol(colMap, ['KODE DOSEN', 'KODE_DOSEN']);
      final colRuangan = _findCol(colMap, ['RUANGAN']);
      final colKelas = _findCol(colMap, ['KELAS']);

      if (colHari == null || colKelas == null || colKodeMk == null) continue;

      String lastHari = '';
      String lastKelas = '';

      for (int i = headerRowIndex + 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        String cell(int? idx) {
          if (idx == null || idx >= row.length) return '';
          final v = row[idx]?.value;
          return v == null ? '' : v.toString().trim();
        }

        final hari = cell(colHari).toUpperCase();
        final kelas = cell(colKelas);

        final effectiveHari = hari.isNotEmpty ? hari : lastHari;
        final effectiveKelas = kelas.isNotEmpty ? kelas : lastKelas;
        if (hari.isNotEmpty) lastHari = hari;
        if (kelas.isNotEmpty) lastKelas = kelas;

        final kodeMk = cell(colKodeMk);
        if (kodeMk.isEmpty) continue;
        if (effectiveHari.isEmpty || effectiveKelas.isEmpty) continue;

        final jamKe = int.tryParse(cell(colJamKe)) ?? 0;
        String jamMulai = '';
        String jamSelesai = '';
        final waktu = cell(colWaktu);
        if (waktu.contains('-')) {
          final parts = waktu.split('-');
          jamMulai = parts[0].trim();
          jamSelesai = parts.length > 1 ? parts[1].trim() : '';
        } else if (jamKe > 0) {
          jamMulai = _jamMulaiMap[jamKe] ?? '';
          jamSelesai = _jamSelesaiMap[jamKe] ?? '';
        }
        if (jamMulai.isEmpty) continue;

        rawRows.add(
          _RawRow(
            hari: effectiveHari,
            kelas: effectiveKelas,
            jamKe: jamKe,
            jamMulai: jamMulai,
            jamSelesai: jamSelesai,
            kodeMk: kodeMk,
            tePr: cell(colTePr),
            kodeDosen: cell(colKodeDosen),
            ruangan: cell(colRuangan),
            semester: semester,
            tahunAkademik: tahunAkademik,
          ),
        );
      }
    }

    return rawRows;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Step 2a — Lookup nama MK
  //
  //  Hive: box 'admin_matkul' → MatkulModel
  //        field: kodeMk (String), namaMatkul (String)
  //  Fallback: MongoDB mataKuliahCollection
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _lookupNamaMk(Set<String> kodes) async {
    final result = <String, String>{};
    if (kodes.isEmpty) return result;

    // ── 1. Hive lokal (admin_matkul) ────────────────────────────────────
    try {
      if (Hive.isBoxOpen(_kBoxMatkul)) {
        final box = Hive.box(_kBoxMatkul);
        for (final v in box.values) {
          // MatkulModel: field kodeMk & namaMatkul
          final dynamic m = v;
          final kode = (m.kodeMk as String?) ?? '';
          final nama = (m.namaMatkul as String?) ?? '';
          if (kode.isNotEmpty && nama.isNotEmpty && kodes.contains(kode)) {
            result[kode] = nama;
          }
        }
        debugPrint(' Hive MK: ${result.length}/${kodes.length} ditemukan');
      }
    } catch (e) {
      debugPrint(' Hive lookup MK: $e');
    }

    // ── 2. MongoDB untuk yang masih kosong ───────────────────────────────
    final missing = kodes.where((k) => !result.containsKey(k)).toSet();
    if (missing.isNotEmpty) {
      try {
        final docs = await MongoDatabase.runSafe(
          () => MongoDatabase.mataKuliahCollection.find(<String, dynamic>{
            'kode_mk': {'\$in': missing.toList()},
          }).toList(),
        );
        for (final d in docs) {
          final kode = d['kode_mk']?.toString() ?? '';
          final nama = d['nama_mk']?.toString() ?? '';
          if (kode.isNotEmpty && nama.isNotEmpty) result[kode] = nama;
        }
        debugPrint(' Mongo MK: ${result.length}/${kodes.length} total');
      } catch (e) {
        debugPrint(' Mongo MK gagal (offline?): $e');
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Step 2b — Lookup nama dosen
  //
  //  Hive: box 'dosen_cache' → Map {'kode_dosen': '...', 'nama_dosen': '...'}
  //        Di-populate oleh DosenCacheService.warmUp() saat app online.
  //  Fallback: MongoDB dosenCollection
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _lookupNamaDosen(Set<String> kodes) async {
    final result = <String, String>{};
    if (kodes.isEmpty) return result;

    // ── 1. Hive cache (dosen_cache) ──────────────────────────────────────
    try {
      if (Hive.isBoxOpen(_kBoxDosenCache)) {
        final box = Hive.box<Map>(_kBoxDosenCache);
        for (final kode in kodes) {
          final raw = box.get(kode); // key = kode_dosen
          if (raw != null) {
            final nama = raw['nama_dosen']?.toString() ?? '';
            if (nama.isNotEmpty) result[kode] = nama;
          }
        }
        debugPrint(' Hive dosen: ${result.length}/${kodes.length} ditemukan');
      }
    } catch (e) {
      debugPrint(' Hive lookup dosen: $e');
    }

    // ── 2. MongoDB untuk yang masih kosong ───────────────────────────────
    final missing = kodes.where((k) => !result.containsKey(k)).toSet();
    if (missing.isNotEmpty) {
      try {
        final docs = await MongoDatabase.runSafe(
          () => MongoDatabase.dosenCollection.find(<String, dynamic>{
            'kode_dosen': {'\$in': missing.toList()},
          }).toList(),
        );
        for (final d in docs) {
          final kode = d['kode_dosen']?.toString() ?? '';
          final nama = d['nama_dosen']?.toString() ?? '';
          if (kode.isNotEmpty && nama.isNotEmpty) result[kode] = nama;
        }
        debugPrint(' Mongo dosen: ${result.length}/${kodes.length} total');
      } catch (e) {
        debugPrint(' Mongo dosen gagal (offline?): $e');
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Step 3 — Merge baris berurutan → 1 ScheduleModel
  // ─────────────────────────────────────────────────────────────────────────
  static List<ScheduleModel> _mergeRows(
    List<_RawRow> rawRows,
    Map<String, String> namaMkMap,
    Map<String, String> namaDosenMap,
    bool needsEnrich,
  ) {
    final results = <ScheduleModel>[];
    _RawRow? current;
    int currentLastJamKe = 0;

    void flush() {
      if (current == null) return;

      final namaMk = namaMkMap[current!.kodeMk] ?? current!.kodeMk;

      final kodeList = current!.kodeDosen
          .split(';')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();

      final String namaDosen = kodeList.isEmpty
          ? '-'
          : kodeList.map((k) => namaDosenMap[k] ?? k).join(';');

      // needsEnrichment = true hanya jika nama masih berupa kode
      final bool enrichmentNeeded =
          needsEnrich &&
          (namaMk == current!.kodeMk ||
              kodeList.any((k) => namaDosen.split(';').contains(k)));

      results.add(
        ScheduleModel(
          id: ObjectId().toHexString(),
          namaMatkul: namaMk,
          namaDosen: namaDosen,
          hari: current!.hari,
          jamMulai: current!.jamMulai,
          jamSelesai: current!.jamSelesai,
          ruangan: current!.ruangan,
          status: 'PUBLISHED',
          createdAt: DateTime.now(),
          kelas: current!.kelas,
          kodeMk: current!.kodeMk,
          kodeDosen: current!.kodeDosen,
          tePr: current!.tePr,
          semester: current!.semester,
          tahunAkademik: current!.tahunAkademik,
          jamKe: current!.jamKe,
          needsEnrichment: enrichmentNeeded,
        ),
      );

      current = null;
      currentLastJamKe = 0;
    }

    for (final row in rawRows) {
      if (current == null) {
        current = row;
        currentLastJamKe = row.jamKe;
        continue;
      }

      final isSameSlot = _mergeKey(current!) == _mergeKey(row);
      final isNext =
          row.jamKe > currentLastJamKe && (row.jamKe - currentLastJamKe) <= 2;

      if (isSameSlot && isNext) {
        current = current!.copyWith(jamSelesai: row.jamSelesai);
        currentLastJamKe = row.jamKe;
      } else {
        flush();
        current = row;
        currentLastJamKe = row.jamKe;
      }
    }
    flush();

    return results;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _mergeKey(_RawRow r) =>
      '${r.hari}|${r.kelas}|${r.kodeMk}|${r.kodeDosen}|${r.tePr}|${r.ruangan}';

  static int? _findCol(Map<String, int> colMap, List<String> candidates) {
    for (final c in candidates) {
      if (colMap.containsKey(c)) return colMap[c];
    }
    return null;
  }

  static const Map<int, String> _jamMulaiMap = {
    1: '07:00',
    2: '07:50',
    3: '08:40',
    4: '09:50',
    5: '10:40',
    6: '11:30',
    7: '13:00',
    8: '13:50',
    9: '14:40',
    10: '15:50',
    11: '16:40',
    12: '17:30',
  };
  static const Map<int, String> _jamSelesaiMap = {
    1: '07:50',
    2: '08:40',
    3: '09:30',
    4: '10:40',
    5: '11:30',
    6: '12:20',
    7: '13:50',
    8: '14:40',
    9: '15:30',
    10: '16:40',
    11: '17:30',
    12: '18:20',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  _RawRow
// ─────────────────────────────────────────────────────────────────────────────
class _RawRow {
  final String hari;
  final String kelas;
  final int jamKe;
  final String jamMulai;
  final String jamSelesai;
  final String kodeMk;
  final String tePr;
  final String kodeDosen;
  final String ruangan;
  final String semester;
  final String tahunAkademik;

  const _RawRow({
    required this.hari,
    required this.kelas,
    required this.jamKe,
    required this.jamMulai,
    required this.jamSelesai,
    required this.kodeMk,
    required this.tePr,
    required this.kodeDosen,
    required this.ruangan,
    required this.semester,
    required this.tahunAkademik,
  });

  _RawRow copyWith({String? jamSelesai}) => _RawRow(
    hari: hari,
    kelas: kelas,
    jamKe: jamKe,
    jamMulai: jamMulai,
    jamSelesai: jamSelesai ?? this.jamSelesai,
    kodeMk: kodeMk,
    tePr: tePr,
    kodeDosen: kodeDosen,
    ruangan: ruangan,
    semester: semester,
    tahunAkademik: tahunAkademik,
  );
}
//new