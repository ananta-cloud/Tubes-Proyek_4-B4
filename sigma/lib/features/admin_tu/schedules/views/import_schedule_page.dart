import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/schedule_excel_parser.dart';
import '../viewmodels/admin_schedule_viewmodel.dart';
import 'package:sigma/data/models/schedule_model.dart';
import 'package:sigma/shared/app_colors.dart';
import '../widgets/info_chip.dart';

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
      final parsed = await ScheduleExcelParser.parse(file.path!);

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

  Future<void> _submit() async {
    final vm = context.read<AdminScheduleViewModel>();
    await vm.importSchedules(_parsedSchedules);

    if (!mounted) return;

    if (!vm.importStatus.contains('kesalahan')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_parsedSchedules.length} jadwal berhasil diimport!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminScheduleViewModel>();
    final hasData = _parsedSchedules.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormatInfo(),
                  const SizedBox(height: 16),
                  _buildFilePicker(hasData),
                  if (_parseError != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorBox(),
                  ],
                  if (hasData) ...[
                    const SizedBox(height: 20),
                    _buildPreviewHeader(),
                    const SizedBox(height: 10),
                    _buildKelasChips(),
                    const SizedBox(height: 14),
                    _buildWarningBox(),
                    const SizedBox(height: 14),
                    _buildPreviewTable(),
                    if (_parsedSchedules.length > 20) _buildMoreLabel(),
                    const SizedBox(height: 24),
                    if (vm.isImporting) _buildImportProgress(vm),
                    _buildSaveButton(vm),
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

  Widget _buildHeader() {
    return Container(
      color: AppColors.white,
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
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.navy,
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
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Format: .xlsx / .xls / .csv',
                  style: TextStyle(color: AppColors.textSub, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.12)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.navy, size: 16),
              SizedBox(width: 8),
              Text(
                'Format Kolom yang Dibutuhkan',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          InfoChip('HARI'),
          InfoChip('JAM KE'),
          InfoChip('WAKTU'),
          InfoChip('KODE MK'),
          InfoChip('TE/PR'),
          InfoChip('KODE DOSEN'),
          InfoChip('RUANGAN'),
          InfoChip('KELAS'),
        ],
      ),
    );
  }

  Widget _buildFilePicker(bool hasData) {
    return GestureDetector(
      onTap: _isParsing ? null : _pickAndParse,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasData
                ? AppColors.success
                : AppColors.navy.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasData
                  ? Icons.check_circle_outline_rounded
                  : Icons.upload_file_rounded,
              color: hasData ? AppColors.success : AppColors.navy,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _isParsing
                  ? 'Memproses & lookup data...'
                  : hasData
                  ? _fileName ?? 'File dipilih'
                  : 'Pilih File Excel',
              style: TextStyle(
                color: hasData ? AppColors.success : AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_isParsing)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Mengambil nama MK & dosen dari database...',
                  style: TextStyle(color: AppColors.textSub, fontSize: 11),
                ),
              ),
            if (hasData)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Tap untuk ganti file',
                  style: TextStyle(color: AppColors.textSub, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _parseError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Row(
      children: [
        const Icon(Icons.table_chart_outlined, color: AppColors.navy, size: 16),
        const SizedBox(width: 8),
        Text(
          'Preview: ${_parsedSchedules.length} jadwal '
          'dari ${_kelasSummary.length} kelas',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildKelasChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _kelasSummary.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '${e.key}: ${e.value} jadwal',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWarningBox() {
    return Container(
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
              'Jadwal lama untuk kelas ${_kelasSummary.keys.join(', ')} '
              'pada semester yang sama akan dihapus dan diganti data baru.',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.navy.withValues(alpha: 0.06),
            ),
            dataRowMinHeight: 36,
            dataRowMaxHeight: 52,
            columnSpacing: 16,
            headingTextStyle: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            dataTextStyle: const TextStyle(color: AppColors.navy, fontSize: 11),
            columns: const [
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Kode MK')),
              DataColumn(label: Text('Nama MK')),
              DataColumn(label: Text('Kode Dosen')),
              DataColumn(label: Text('Nama Dosen')),
              DataColumn(label: Text('Hari')),
              DataColumn(label: Text('Jam Mulai')),
              DataColumn(label: Text('Jam Selesai')),
              DataColumn(label: Text('Ruangan')),
              DataColumn(label: Text('TE/PR')),
            ],
            rows: _parsedSchedules.take(20).map((s) {
              return DataRow(
                cells: [
                  DataCell(Text(s.kelas)),
                  DataCell(Text(s.kodeMk)),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        s.namaMatkul,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 110,
                      child: Text(
                        s.kodeDosen.replaceAll(';', '\n'),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 130,
                      child: Text(
                        s.namaDosen.replaceAll(';', '\n'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(s.hari)),
                  DataCell(Text(s.jamMulai)),
                  DataCell(Text(s.jamSelesai)),
                  DataCell(Text(s.ruangan)),
                  DataCell(Text(s.tePr)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '... dan ${_parsedSchedules.length - 20} jadwal lainnya',
        style: const TextStyle(color: AppColors.textSub, fontSize: 12),
      ),
    );
  }

  Widget _buildImportProgress(AdminScheduleViewModel vm) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              vm.importStatus,
              style: const TextStyle(color: AppColors.textSub, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AdminScheduleViewModel vm) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: vm.isImporting ? null : _submit,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: vm.isImporting ? AppColors.textSub : AppColors.navy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: vm.isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.save_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Simpan ${_parsedSchedules.length} Jadwal',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
