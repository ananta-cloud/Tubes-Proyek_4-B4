import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:mongo_dart/mongo_dart.dart' hide Box, State, Center;

import '../../main/views/admin_main_page.dart';
import '../viewmodels/admin_schedule_viewmodel.dart';
import '../models/schedule_model.dart';

class ImportSchedulePage extends StatefulWidget {
  const ImportSchedulePage({super.key});

  @override
  State<ImportSchedulePage> createState() => _ImportSchedulePageState();
}

class _ImportSchedulePageState extends State<ImportSchedulePage> {
  bool _isParsing = false;
  String? _fileName;
  String? _parseError;
  List<ScheduleModel> _parsedSchedules = [];
  Map<String, int> _kelasSummary = {};

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

  // ── Pick & Parse ──────────────────────────────────────────────────────────
  Future<void> _pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    setState(() {
      _isParsing = true;
      _parseError = null;
      _parsedSchedules = [];
      _kelasSummary = {};
      _fileName = file.name;
    });

    try {
      final parsed = await _parseExcel(file.path!);
      final summary = <String, int>{};
      for (final s in parsed) {
        summary[s.kelas] = (summary[s.kelas] ?? 0) + 1;
      }
      setState(() {
        _parsedSchedules = parsed;
        _kelasSummary = summary;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _parseError = 'Gagal parse file: $e';
        _isParsing = false;
      });
    }
  }

  Future<List<ScheduleModel>> _parseExcel(String path) async {
    final bytes = await File(path).readAsBytes();
    final excelFile = excel_pkg.Excel.decodeBytes(bytes);
    final results = <ScheduleModel>[];

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
        final tahunMatch = RegExp(r'(\d{4}/\d{4})').firstMatch(rowText);
        if (tahunMatch != null) tahunAkademik = tahunMatch.group(1)!;
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
      final colNamaMk = _findCol(colMap, ['NAMA MK', 'NAMA_MK', 'NAMAMK']);
      final colTePr = _findCol(colMap, ['TE/PR', 'TEPR', 'TE_PR']);
      final colKodeDosen = _findCol(colMap, ['KODE DOSEN', 'KODE_DOSEN']);
      final colNamaDosen = _findCol(colMap, ['NAMA DOSEN', 'NAMA_DOSEN']);
      final colRuangan = _findCol(colMap, ['RUANGAN']);
      final colKelas = _findCol(colMap, ['KELAS']);

      if (colHari == null || colKelas == null) continue;

      String lastHari = '';
      String lastKelas = '';

      for (int i = headerRowIndex + 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        String cell(int? idx) {
          if (idx == null || idx >= row.length) return '';
          final c = row[idx];
          if (c == null) return '';
          final v = c.value;
          if (v == null) return '';
          return v.toString().trim();
        }

        final hari = cell(colHari).toUpperCase();
        final kelas = cell(colKelas);

        final effectiveHari = hari.isNotEmpty ? hari : lastHari;
        final effectiveKelas = kelas.isNotEmpty ? kelas : lastKelas;
        if (hari.isNotEmpty) lastHari = hari;
        if (kelas.isNotEmpty) lastKelas = kelas;

        final kodeMk = cell(colKodeMk);
        final namaMk = cell(colNamaMk);

        if (kodeMk.isEmpty && namaMk.isEmpty) continue;
        if (namaMk.toUpperCase().contains('ISTIRAHAT')) continue;

        final jamKeStr = cell(colJamKe);
        final jamKe = int.tryParse(jamKeStr) ?? 0;

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

        final model = ScheduleModel(
          // ✅ FIX #2: toHexString() deprecated → gunakan .oid
          id: ObjectId().oid,
          namaMatkul: namaMk.isNotEmpty ? namaMk : '-',
          namaDosen: cell(colNamaDosen).isNotEmpty ? cell(colNamaDosen) : '-',
          hari: effectiveHari,
          jamMulai: jamMulai,
          jamSelesai: jamSelesai,
          ruangan: cell(colRuangan),
          status: 'PUBLISHED',
          createdAt: DateTime.now(),
          kelas: effectiveKelas,
          kodeMk: kodeMk,
          kodeDosen: cell(colKodeDosen),
          tePr: cell(colTePr),
          semester: semester,
          tahunAkademik: tahunAkademik,
          jamKe: jamKe,
        );

        results.add(model);
      }
    }

    if (results.isEmpty) {
      throw Exception(
        'Tidak ada data yang berhasil diparsing. '
        'Pastikan format kolom sesuai: HARI, KODE MK, NAMA MK, '
        'KODE DOSEN, NAMA DOSEN, RUANGAN, KELAS.',
      );
    }

    return results;
  }

  int? _findCol(Map<String, int> colMap, List<String> candidates) {
    for (final c in candidates) {
      if (colMap.containsKey(c)) return colMap[c];
    }
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final vm = context.read<AdminScheduleViewModel>();
    await vm.importSchedules(_parsedSchedules);

    if (!mounted) return;

    if (!vm.importStatus.contains('kesalahan')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_parsedSchedules.length} jadwal berhasil diimport!'),
          backgroundColor: SigmaColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminScheduleViewModel>();
    final hasData = _parsedSchedules.isNotEmpty;

    return Scaffold(
      backgroundColor: SigmaColors.bgPage,
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: SigmaColors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 14,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SigmaColors.bgPage,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: SigmaColors.navy,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Jadwal dari Excel',
                        style: TextStyle(
                          color: SigmaColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Format: .xlsx / .xls / .csv',
                        style: TextStyle(
                          color: SigmaColors.textSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info format ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      // ✅ FIX #3: withOpacity() deprecated → withValues()
                      color: SigmaColors.navy.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: SigmaColors.navy.withValues(alpha: 0.12),
                      ),
                    ),
                    // ✅ FIX #4: _infoChip() method diganti jadi _InfoChip widget
                    // agar bisa dipakai dalam const Column
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: SigmaColors.navy,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Format Kolom yang Dibutuhkan',
                              style: TextStyle(
                                color: SigmaColors.navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        _InfoChip('HARI'),
                        _InfoChip('JAM KE'),
                        _InfoChip('WAKTU'),
                        _InfoChip('KODE MK'),
                        _InfoChip('NAMA MK'),
                        _InfoChip('TE/PR'),
                        _InfoChip('KODE DOSEN'),
                        _InfoChip('NAMA DOSEN'),
                        _InfoChip('RUANGAN'),
                        _InfoChip('KELAS'),
                        SizedBox(height: 6),
                        Text(
                          'Baris dengan kolom NAMA MK kosong atau '
                          '"ISTIRAHAT" akan diabaikan otomatis.',
                          style: TextStyle(
                            color: SigmaColors.textSub,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Tombol pilih file ──
                  GestureDetector(
                    onTap: _isParsing ? null : _pickAndParse,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: SigmaColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasData
                              ? SigmaColors.success
                              : SigmaColors.navy.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            hasData
                                ? Icons.check_circle_outline_rounded
                                : Icons.upload_file_rounded,
                            color: hasData
                                ? SigmaColors.success
                                : SigmaColors.navy,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isParsing
                                ? 'Memproses...'
                                : hasData
                                ? _fileName ?? 'File dipilih'
                                : 'Pilih File Excel',
                            style: TextStyle(
                              color: hasData
                                  ? SigmaColors.success
                                  : SigmaColors.navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hasData)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Tap untuk ganti file',
                                style: TextStyle(
                                  color: SigmaColors.textSub,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Error ──
                  if (_parseError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SigmaColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: SigmaColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: SigmaColors.danger,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _parseError!,
                              style: const TextStyle(
                                color: SigmaColors.danger,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Preview ──
                  if (hasData) ...[
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Icon(
                          Icons.table_chart_outlined,
                          color: SigmaColors.navy,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Preview: ${_parsedSchedules.length} baris '
                          'dari ${_kelasSummary.length} kelas',
                          style: const TextStyle(
                            color: SigmaColors.navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _kelasSummary.entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: SigmaColors.navy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${e.key}: ${e.value} jadwal',
                            style: const TextStyle(
                              color: SigmaColors.navy,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Peringatan duplikat
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFB45309),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Jadwal lama untuk kelas '
                              '${_kelasSummary.keys.join(', ')} pada semester '
                              'yang sama akan dihapus dan diganti data baru.',
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tabel preview
                    Container(
                      decoration: BoxDecoration(
                        color: SigmaColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SigmaColors.cardBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            // ✅ WidgetStateProperty tidak boleh di-const
                            headingRowColor: WidgetStateProperty.all(
                              SigmaColors.navy.withValues(alpha: 0.06),
                            ),
                            dataRowMinHeight: 36,
                            dataRowMaxHeight: 48,
                            columnSpacing: 16,
                            headingTextStyle: const TextStyle(
                              color: SigmaColors.navy,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            dataTextStyle: const TextStyle(
                              color: SigmaColors.navy,
                              fontSize: 11,
                            ),
                            columns: const [
                              DataColumn(label: Text('Kelas')),
                              DataColumn(label: Text('Hari')),
                              DataColumn(label: Text('Jam')),
                              DataColumn(label: Text('Kode MK')),
                              DataColumn(label: Text('Nama MK')),
                              DataColumn(label: Text('Dosen')),
                              DataColumn(label: Text('Ruangan')),
                              DataColumn(label: Text('TE/PR')),
                            ],
                            rows: _parsedSchedules
                                .take(20)
                                .map(
                                  (s) => DataRow(
                                    cells: [
                                      DataCell(Text(s.kelas)),
                                      DataCell(Text(s.hari)),
                                      DataCell(
                                        Text('${s.jamMulai}–${s.jamSelesai}'),
                                      ),
                                      DataCell(Text(s.kodeMk)),
                                      DataCell(
                                        SizedBox(
                                          width: 160,
                                          child: Text(
                                            s.namaMatkul,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 140,
                                          child: Text(
                                            s.namaDosen,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(s.ruangan)),
                                      DataCell(Text(s.tePr)),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),

                    if (_parsedSchedules.length > 20)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '... dan ${_parsedSchedules.length - 20} baris lainnya',
                          style: const TextStyle(
                            color: SigmaColors.textSub,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    if (vm.isImporting)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SigmaColors.navy,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                vm.importStatus,
                                style: const TextStyle(
                                  color: SigmaColors.textSub,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Tombol simpan
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: vm.isImporting ? null : _submit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: vm.isImporting
                                ? SigmaColors.textSub
                                : SigmaColors.navy,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: vm.isImporting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: SigmaColors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.save_rounded,
                                        color: SigmaColors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Simpan ${_parsedSchedules.length} Jadwal',
                                        style: const TextStyle(
                                          color: SigmaColors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ FIX #5: Jadikan StatelessWidget top-level (bukan method dalam class)
// agar bisa dipakai sebagai const di dalam Column
class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: SigmaColors.success, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: SigmaColors.navy,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
