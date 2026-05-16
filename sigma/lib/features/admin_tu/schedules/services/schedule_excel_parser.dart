import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:mongo_dart/mongo_dart.dart' hide Box, State, Center;

import '../models/schedule_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ScheduleExcelParser
//  Dipanggil dari ImportSchedulePage lewat: ScheduleExcelParser.parse(path)
// ─────────────────────────────────────────────────────────────────────────────
class ScheduleExcelParser {
  ScheduleExcelParser._();

  // ── Public entry point ────────────────────────────────────────────────────
  static Future<List<ScheduleModel>> parse(String filePath) async {
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

      // ── Cari baris header & info semester/tahun ──────────────────────────
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
        final tahunMatch = RegExp(r'(\d{4}/\d{4})').firstMatch(rowText);
        if (tahunMatch != null) tahunAkademik = tahunMatch.group(1)!;
      }
      if (headerRowIndex == -1) continue;

      // ── Petakan nama kolom → index ────────────────────────────────────────
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
      final colNamaMk = _findCol(colMap, ['NAMA MK', 'NAMA_MK', 'NAMAMK']);
      final colTePr = _findCol(colMap, ['TE/PR', 'TEPR', 'TE_PR']);
      final colKodeDosen = _findCol(colMap, ['KODE DOSEN', 'KODE_DOSEN']);
      final colNamaDosen = _findCol(colMap, ['NAMA DOSEN', 'NAMA_DOSEN']);
      final colRuangan = _findCol(colMap, ['RUANGAN']);
      final colKelas = _findCol(colMap, ['KELAS']);

      if (colHari == null || colKelas == null) continue;

      // ── Parse baris data ──────────────────────────────────────────────────
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
        final namaMk = cell(colNamaMk);

        // Skip baris kosong / istirahat
        if (kodeMk.isEmpty && namaMk.isEmpty) continue;
        if (namaMk.toUpperCase().contains('ISTIRAHAT')) continue;
        if (effectiveHari.isEmpty || effectiveKelas.isEmpty) continue;

        // ── Resolusi waktu ────────────────────────────────────────────────
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
            namaMk: namaMk.isNotEmpty ? namaMk : '-',
            tePr: cell(colTePr),
            kodeDosen: cell(colKodeDosen),
            namaDosen: cell(colNamaDosen).isNotEmpty ? cell(colNamaDosen) : '-',
            ruangan: cell(colRuangan),
            semester: semester,
            tahunAkademik: tahunAkademik,
          ),
        );
      }
    }

    if (rawRows.isEmpty) {
      throw Exception(
        'Tidak ada data yang berhasil diparsing. '
        'Pastikan format kolom sesuai: HARI, KODE MK, NAMA MK, '
        'KODE DOSEN, NAMA DOSEN, RUANGAN, KELAS.',
      );
    }

    return _mergeRows(rawRows);
  }

  // ── Merge: gabungkan baris berurutan menjadi 1 jadwal ────────────────────
  //
  //  Dua baris dianggap "sambungan" jika:
  //    1. _mergeKey sama (hari, kelas, kodeMk, kodeDosen, tePr, ruangan)
  //    2. jamKe baru > jamKe terakhir
  //    3. Selisih jamKe ≤ 2 (toleransi 1 slot istirahat yang sudah di-skip)
  //
  static List<ScheduleModel> _mergeRows(List<_RawRow> rawRows) {
    final results = <ScheduleModel>[];
    _RawRow? current;
    int currentLastJamKe = 0;

    void flush() {
      if (current == null) return;
      results.add(
        ScheduleModel(
          id: ObjectId().oid,
          namaMatkul: current!.namaMk,
          namaDosen: current!.namaDosen,
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
        // Perpanjang jamSelesai ke jam akhir baris ini
        current = current!.copyWith(jamSelesai: row.jamSelesai);
        currentLastJamKe = row.jamKe;
      } else {
        flush();
        current = row;
        currentLastJamKe = row.jamKe;
      }
    }
    flush(); // flush entry terakhir

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

  // ── Lookup tabel jam ──────────────────────────────────────────────────────
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
//  _RawRow — model internal, hanya dipakai dalam parser ini
// ─────────────────────────────────────────────────────────────────────────────
class _RawRow {
  final String hari;
  final String kelas;
  final int jamKe;
  final String jamMulai;
  final String jamSelesai;
  final String kodeMk;
  final String namaMk;
  final String tePr;
  final String kodeDosen;
  final String namaDosen;
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
    required this.namaMk,
    required this.tePr,
    required this.kodeDosen,
    required this.namaDosen,
    required this.ruangan,
    required this.semester,
    required this.tahunAkademik,
  });

  // copyWith hanya untuk field yang perlu diubah saat merge
  _RawRow copyWith({String? jamSelesai}) => _RawRow(
    hari: hari,
    kelas: kelas,
    jamKe: jamKe,
    jamMulai: jamMulai,
    jamSelesai: jamSelesai ?? this.jamSelesai,
    kodeMk: kodeMk,
    namaMk: namaMk,
    tePr: tePr,
    kodeDosen: kodeDosen,
    namaDosen: namaDosen,
    ruangan: ruangan,
    semester: semester,
    tahunAkademik: tahunAkademik,
  );
}
