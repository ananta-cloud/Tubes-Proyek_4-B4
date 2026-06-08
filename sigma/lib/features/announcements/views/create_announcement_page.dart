import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../viewmodels/admin_announcement_viewmodel.dart';
import '../../auth/viewmodels/login_viewmodel.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:sigma/shared/app_colors.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();

  // Multi-select kategori
  final Set<String> _selectedKategori = {};

  String _selectedTarget = 'SEMUA';
  String? _selectedProdi; // null = tidak dipilih
  String _selectedTingkat = 'BIASA';
  DateTime? _selectedDeadline;

  // File attachments
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;

  static const _kategoriList = [
    'Akademik',
    'Beasiswa',
    'Lomba',
    'UKM',
    'Karir',
    'Umum',
    'Penelitian',
    'Pengabdian',
    'Pengajaran',
  ];

  static const _targetList = ['SEMUA', 'MAHASISWA', 'DOSEN'];

  // Pilihan prodi statis (Jika target MAHASISWA oleh Admin TU)
  static const _prodiList = ['D3 Teknik Informatika', 'D4 Teknik Informatika'];

  static const _tingkatColors = {
    'BIASA': AppColors.textSub,
    'PENTING': Color(0xFFF59E0B),
    'SANGAT PENTING': AppColors.danger,
  };

  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  bool get _isTargetMahasiswa => _selectedTarget == 'MAHASISWA';

  // ===========================================================================
  // INIT STATE (Memuat jurusan jika role MANAJEMEN)
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<LoginViewModel>().user;
      // Jika user MANAJEMEN, load list jurusan dari MongoDB
      if (user?.role.toUpperCase() == 'MANAJEMEN') {
        context.read<AdminAnnouncementViewModel>().fetchJurusan();
      }
    });
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  // ─── Deadline → auto tingkat kepentingan ─────────────────────────────────
  void _onDeadlineChanged(DateTime? date) {
    setState(() {
      _selectedDeadline = date;
      if (date == null) {
        _selectedTingkat = 'BIASA';
      } else {
        final diff = date.difference(DateTime.now()).inDays;
        if (diff <= 3) {
          _selectedTingkat = 'SANGAT PENTING';
        } else if (diff <= 7) {
          _selectedTingkat = 'PENTING';
        } else {
          _selectedTingkat = 'BIASA';
        }
      }
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navy,
            onPrimary: AppColors.white,
            surface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) _onDeadlineChanged(picked);
  }

  void _clearDeadline() => _onDeadlineChanged(null);

  // ─── Pick File ────────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null) return;

    final oversized = <String>[];
    final valid = <PlatformFile>[];

    for (final file in result.files) {
      if (file.size > _maxFileSizeBytes) {
        oversized.add(file.name);
      } else {
        final existing = _selectedFiles.map((f) => f.name).toSet();
        if (!existing.contains(file.name)) valid.add(file);
      }
    }

    if (oversized.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File berikut melebihi 5MB dan dilewati: ${oversized.join(', ')}',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }

    if (valid.isNotEmpty) setState(() => _selectedFiles.addAll(valid));
  }

  void _removeFile(int index) => setState(() => _selectedFiles.removeAt(index));

  Future<List<Map<String, String>>> _encodeFiles() async {
    final encoded = <Map<String, String>>[];
    for (final file in _selectedFiles) {
      if (file.path == null) continue;
      try {
        final bytes = await File(file.path!).readAsBytes();
        encoded.add({
          'name': file.name,
          'type': file.extension?.toLowerCase() ?? 'file',
          'data': base64Encode(bytes),
          'size': file.size.toString(),
        });
      } catch (e) {
        debugPrint('❌ Encode file ${file.name}: $e');
      }
    }
    return encoded;
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_judulCtrl.text.trim().isEmpty || _isiCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan isi tidak boleh kosong.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    List<Map<String, String>> attachments = [];
    if (_selectedFiles.isNotEmpty) attachments = await _encodeFiles();
    setState(() => _isUploading = false);

    if (!mounted) return;

    final currentUser = context.read<LoginViewModel>().user;
    final isManajemen = currentUser?.role.toUpperCase() == 'MANAJEMEN';

    // Susun target string: kalau MAHASISWA + prodi dipilih, tambahkan info prodi
    String targetFinal = _selectedTarget;
    if (_isTargetMahasiswa && _selectedProdi != null) {
      targetFinal = 'Mahasiswa ($_selectedProdi)';
    }

    final vm = context.read<AdminAnnouncementViewModel>();

    // Panggil fungsi create yang sudah dilengkapi publisher & jurusan/prodi
    await vm.createAnnouncement(
      judul: _judulCtrl.text.trim(),
      isi: _isiCtrl.text.trim(),
      kategoriList: _selectedKategori.isEmpty
          ? ['Umum']
          : _selectedKategori.toList(),
      target: targetFinal,
      tingkatKepentingan: _selectedTingkat,
      deadline: _selectedDeadline,
      attachments: attachments,
      // Parameter identitas pengirim
      idPublisher: currentUser?.id ?? '',
      namaPublisher: currentUser?.nama ?? 'Admin',
      rolePublisher: currentUser?.role ?? 'ADMIN_TU',
      // Parameter khusus Manajemen
      idJurusan: isManajemen ? vm.selectedJurusanId : null,
      idProdi: isManajemen ? vm.selectedProdiId : null,
    );

    if (mounted) {
      if (isManajemen) vm.clearManajemenSelections(); // Bersihkan pilihan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengumuman berhasil diterbitkan!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminAnnouncementViewModel>();
    final currentUser = context.read<LoginViewModel>().user;
    final bool isManajemen = currentUser?.role.toUpperCase() == 'MANAJEMEN';

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: AppColors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 12,
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
                        'Buat Pengumuman Baru',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Semester Genap 2025/2026',
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Form ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header form
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.navy.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: AppColors.navy,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Form Pengumuman',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pengumuman akan dikirim via Push Notification ke target audiens.',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Judul ──────────────────────────────────────────
                        const _FieldLabel(
                          label: 'Judul Pengumuman',
                          required: true,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _judulCtrl,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.navy,
                          ),
                          decoration: _inputDeco(
                            hint: 'Cth: Perubahan Jadwal Ujian Basis Data...',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Kategori (multi-select, full width) ───────────
                        const _FieldLabel(label: 'Kategori'),
                        const SizedBox(height: 4),
                        const Text(
                          'Dapat memilih lebih dari satu',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _kategoriList.map((k) {
                            final isSelected = _selectedKategori.contains(k);
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (isSelected) {
                                  _selectedKategori.remove(k);
                                } else {
                                  _selectedKategori.add(k);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.navy
                                      : AppColors.bgPage,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.navy
                                        : AppColors.cardBorder,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  k,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.textSub,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // ── Target + Prodi (2 kolom untuk Admin TU) ───────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Target
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel(label: 'Target'),
                                  const SizedBox(height: 6),
                                  _SigmaDropdown<String>(
                                    value: _selectedTarget,
                                    hint: 'Pilih...',
                                    items: _targetList,
                                    labelBuilder: (e) => e,
                                    onChanged: (v) => setState(() {
                                      _selectedTarget = v ?? 'SEMUA';
                                      if (_selectedTarget != 'MAHASISWA') {
                                        _selectedProdi = null;
                                      }
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            // Sembunyikan dropdown prodi statis jika Role MANAJEMEN
                            if (!isManajemen) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _isTargetMahasiswa ? 1.0 : 0.35,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Flexible(
                                            child: _FieldLabel(
                                              label: 'Prodi (Opsional)',
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          if (!_isTargetMahasiswa)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.textSub
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'nonaktif',
                                                style: TextStyle(
                                                  color: AppColors.textSub,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      _SigmaDropdown<String>(
                                        value: _selectedProdi,
                                        hint: 'Semua prodi',
                                        items: _prodiList,
                                        labelBuilder: (e) => e,
                                        onChanged: _isTargetMahasiswa
                                            ? (v) => setState(
                                                () => _selectedProdi = v,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // ─── DROPDOWN JURUSAN & PRODI KHUSUS MANAJEMEN ───
                        if (isManajemen) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.navy.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.navy.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      size: 16,
                                      color: AppColors.navy,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Target Spesifik (Khusus Manajemen)',
                                      style: TextStyle(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const _FieldLabel(label: 'Jurusan'),
                                const SizedBox(height: 6),
                                _SigmaDropdown<String>(
                                  value: vm.selectedJurusanId,
                                  hint: 'Pilih Jurusan...',
                                  items: vm.listJurusan
                                      .map(
                                        (j) => (j['_id'] as ObjectId)
                                            .toHexString(),
                                      )
                                      .toList(),
                                  labelBuilder: (id) {
                                    try {
                                      return vm.listJurusan
                                          .firstWhere(
                                            (j) =>
                                                (j['_id'] as ObjectId)
                                                    .toHexString() ==
                                                id,
                                          )['nama_jurusan']
                                          .toString();
                                    } catch (e) {
                                      return 'Unknown';
                                    }
                                  },
                                  onChanged: (val) => context
                                      .read<AdminAnnouncementViewModel>()
                                      .setJurusan(val),
                                ),
                                const SizedBox(height: 12),
                                const _FieldLabel(label: 'Program Studi'),
                                const SizedBox(height: 6),
                                _SigmaDropdown<String>(
                                  value: vm.selectedProdiId,
                                  hint: vm.listProdi.isEmpty
                                      ? 'Pilih Jurusan dahulu...'
                                      : 'Semua Prodi di Jurusan ini...',
                                  items: vm.listProdi
                                      .map(
                                        (p) => (p['_id'] as ObjectId)
                                            .toHexString(),
                                      )
                                      .toList(),
                                  labelBuilder: (id) {
                                    try {
                                      return vm.listProdi
                                          .firstWhere(
                                            (p) =>
                                                (p['_id'] as ObjectId)
                                                    .toHexString() ==
                                                id,
                                          )['nama_prodi']
                                          .toString();
                                    } catch (e) {
                                      return 'Unknown';
                                    }
                                  },
                                  onChanged: vm.listProdi.isEmpty
                                      ? null
                                      : (val) => context
                                            .read<AdminAnnouncementViewModel>()
                                            .setProdi(val),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ────────────────────────────────────────────────────────
                        const SizedBox(height: 16),

                        // ── Deadline (opsional) ────────────────────────────
                        Row(
                          children: [
                            const _FieldLabel(label: 'Deadline'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textSub.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'opsional',
                                style: TextStyle(
                                  color: AppColors.textSub,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '≤ 3 hari → Sangat Penting · ≤ 7 hari → Penting · Tidak ada → Biasa',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDeadline,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgPage,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedDeadline != null
                                    ? AppColors.navy
                                    : AppColors.cardBorder,
                                width: _selectedDeadline != null ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_rounded,
                                  size: 16,
                                  color: _selectedDeadline != null
                                      ? AppColors.navy
                                      : AppColors.textSub,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDeadline != null
                                        ? DateFormat(
                                            'd MMMM yyyy',
                                            'id_ID',
                                          ).format(_selectedDeadline!)
                                        : 'Pilih tanggal deadline...',
                                    style: TextStyle(
                                      color: _selectedDeadline != null
                                          ? AppColors.navy
                                          : AppColors.textSub,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (_selectedDeadline != null)
                                  GestureDetector(
                                    onTap: _clearDeadline,
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.textSub,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Tingkat Kepentingan ────────────────────────────
                        Row(
                          children: [
                            const _FieldLabel(label: 'Tingkat Kepentingan'),
                            const SizedBox(width: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _selectedDeadline != null
                                  ? Container(
                                      key: const ValueKey('auto'),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.navy.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'otomatis dari deadline',
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      key: const ValueKey('manual'),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.textSub.withOpacity(
                                          0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'pilih manual',
                                        style: TextStyle(
                                          color: AppColors.textSub,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ['BIASA', 'PENTING', 'SANGAT PENTING'].map((
                            tingkat,
                          ) {
                            final isSelected = _selectedTingkat == tingkat;
                            final isLocked = _selectedDeadline != null;
                            final color =
                                _tingkatColors[tingkat] ?? AppColors.textSub;
                            return Expanded(
                              child: GestureDetector(
                                onTap: isLocked
                                    ? null
                                    : () => setState(
                                        () => _selectedTingkat = tingkat,
                                      ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(
                                    right: tingkat != 'SANGAT PENTING' ? 8 : 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withOpacity(0.12)
                                        : AppColors.bgPage,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : AppColors.cardBorder,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        tingkat == 'BIASA'
                                            ? Icons.info_outline_rounded
                                            : tingkat == 'PENTING'
                                            ? Icons.warning_amber_rounded
                                            : Icons.error_rounded,
                                        color: isSelected
                                            ? color
                                            : AppColors.textSub,
                                        size: 18,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tingkat,
                                        style: TextStyle(
                                          color: isSelected
                                              ? color
                                              : AppColors.textSub,
                                          fontSize: 9,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // ── Isi ────────────────────────────────────────────
                        const _FieldLabel(
                          label: 'Isi Pengumuman',
                          required: true,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _isiCtrl,
                          maxLines: 5,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.navy,
                          ),
                          decoration: _inputDeco(
                            hint: 'Tuliskan detail pengumuman di sini...',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Upload Lampiran ────────────────────────────────
                        const _FieldLabel(label: 'Lampiran'),
                        const SizedBox(height: 4),
                        const Text(
                          'PDF, PNG, JPG, JPEG • Maks. 5 MB per file',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickFile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgPage,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.navy.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.attach_file_rounded,
                                  color: AppColors.navy,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Pilih File',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_selectedFiles.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ..._selectedFiles.asMap().entries.map((entry) {
                            final i = entry.key;
                            final file = entry.value;
                            final isImage = [
                              'png',
                              'jpg',
                              'jpeg',
                            ].contains(file.extension?.toLowerCase());
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isImage
                                        ? Icons.image_outlined
                                        : Icons.picture_as_pdf_outlined,
                                    color: isImage
                                        ? AppColors.accent
                                        : AppColors.danger,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(file.size / 1024).toStringAsFixed(1)} KB',
                                    style: const TextStyle(
                                      color: AppColors.textSub,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeFile(i),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.danger,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        if (_isUploading)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.navy,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Memproses lampiran...',
                                  style: TextStyle(
                                    color: AppColors.textSub,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.navy.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.navy,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isManajemen
                                ? 'Pengumuman ini dapat difilter spesifik untuk Jurusan dan Prodi yang Anda pilih di atas.'
                                : 'Pengumuman ini akan otomatis ditargetkan ke jurusan Anda. Pilih target spesifik untuk mempersempit jangkauan.',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tombol aksi
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.bgPage,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Center(
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  color: AppColors.textSub,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: (vm.isLoading || _isUploading)
                              ? null
                              : _submit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: (vm.isLoading || _isUploading)
                                  ? AppColors.textSub
                                  : AppColors.navy,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: (vm.isLoading || _isUploading)
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.send_rounded,
                                          color: AppColors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Terbitkan Pengumuman',
                                          style: TextStyle(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({required String hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSub, fontSize: 13),
    filled: true,
    fillColor: AppColors.bgPage,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _SigmaDropdown<T> extends StatelessWidget {
  const _SigmaDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: AppColors.textSub, fontSize: 13),
          ),
          isExpanded: true,
          dropdownColor: AppColors.white,
          style: const TextStyle(color: AppColors.navy, fontSize: 13),
          onChanged: onChanged,
          items: items
              .map(
                (e) =>
                    DropdownMenuItem<T>(value: e, child: Text(labelBuilder(e))),
              )
              .toList(),
        ),
      ),
    );
  }
}
