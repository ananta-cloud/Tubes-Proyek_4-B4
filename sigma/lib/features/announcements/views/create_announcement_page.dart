import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../admin_tu/main/views/admin_main_page.dart';
import '../viewmodels/admin_announcement_viewmodel.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();

  String? _selectedKategori;
  String _selectedTarget = 'SEMUA';
  String _selectedTingkat = 'BIASA'; // ← default

  static const _kategoriList = [
    'Akademik',
    'Beasiswa',
    'Lomba',
    'UKM',
    'Karir',
    'Umum',
  ];

  static const _targetList = ['SEMUA', 'MAHASISWA', 'DOSEN'];

  // Tingkat kepentingan sesuai permintaan
  static const _tingkatList = ['BIASA', 'PENTING', 'SANGAT PENTING'];

  // Warna badge per tingkat
  static const _tingkatColors = {
    'BIASA': SigmaColors.textSub,
    'PENTING': Color(0xFFF59E0B),
    'SANGAT PENTING': SigmaColors.danger,
  };

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_judulCtrl.text.trim().isEmpty || _isiCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan isi tidak boleh kosong.'),
          backgroundColor: SigmaColors.danger,
        ),
      );
      return;
    }

    final vm = context.read<AdminAnnouncementViewModel>();
    await vm.createAnnouncement(
      judul: _judulCtrl.text.trim(),
      isi: _isiCtrl.text.trim(),
      kategori: _selectedKategori ?? 'Umum',
      target: _selectedTarget,
      tingkatKepentingan: _selectedTingkat,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengumuman berhasil diterbitkan!'),
          backgroundColor: SigmaColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminAnnouncementViewModel>();

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
              bottom: 12,
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
                        'Buat Pengumuman Baru',
                        style: TextStyle(
                          color: SigmaColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Semester Genap 2025/2026',
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
                      color: SigmaColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SigmaColors.cardBorder),
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
                                color: SigmaColors.navy.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: SigmaColors.navy,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Form Pengumuman Jurusan',
                              style: TextStyle(
                                color: SigmaColors.navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pengumuman akan dikirim via Push Notification ke mahasiswa sesuai target.',
                          style: TextStyle(
                            color: SigmaColors.textSub,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Judul
                        _FieldLabel(label: 'Judul Pengumuman', required: true),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _judulCtrl,
                          style: const TextStyle(
                            fontSize: 14,
                            color: SigmaColors.navy,
                          ),
                          decoration: _inputDeco(
                            hint: 'Cth: Perubahan Jadwal Ujian Basis Data...',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Kategori + Target
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel(label: 'Kategori'),
                                  const SizedBox(height: 6),
                                  _SigmaDropdown<String>(
                                    value: _selectedKategori,
                                    hint: 'Pilih...',
                                    items: _kategoriList,
                                    labelBuilder: (e) => e,
                                    onChanged: (v) =>
                                        setState(() => _selectedKategori = v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                    onChanged: (v) => setState(
                                      () => _selectedTarget = v ?? 'SEMUA',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Tingkat Kepentingan ──────────────────────────────
                        const _FieldLabel(label: 'Tingkat Kepentingan'),
                        const SizedBox(height: 6),
                        Row(
                          children: _tingkatList.map((tingkat) {
                            final isSelected = _selectedTingkat == tingkat;
                            final color =
                                _tingkatColors[tingkat] ?? SigmaColors.textSub;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedTingkat = tingkat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: EdgeInsets.only(
                                    right: tingkat != _tingkatList.last ? 8 : 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withOpacity(0.12)
                                        : SigmaColors.bgPage,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : SigmaColors.cardBorder,
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
                                            : SigmaColors.textSub,
                                        size: 18,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tingkat,
                                        style: TextStyle(
                                          color: isSelected
                                              ? color
                                              : SigmaColors.textSub,
                                          fontSize: 10,
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

                        // Isi
                        _FieldLabel(label: 'Isi Pengumuman', required: true),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _isiCtrl,
                          maxLines: 5,
                          style: const TextStyle(
                            fontSize: 14,
                            color: SigmaColors.navy,
                          ),
                          decoration: _inputDeco(
                            hint: 'Tuliskan detail pengumuman di sini...',
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
                      color: SigmaColors.navy.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: SigmaColors.navy.withOpacity(0.12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: SigmaColors.navy,
                          size: 15,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pengumuman ini akan otomatis ditargetkan ke jurusan Anda. Pilih target spesifik untuk mempersempit jangkauan.',
                            style: TextStyle(
                              color: SigmaColors.navy,
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
                              color: SigmaColors.bgPage,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SigmaColors.cardBorder),
                            ),
                            child: const Center(
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  color: SigmaColors.textSub,
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
                          onTap: vm.isLoading ? null : _submit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: vm.isLoading
                                  ? SigmaColors.textSub
                                  : SigmaColors.navy,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: vm.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: SigmaColors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.send_rounded,
                                          color: SigmaColors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Terbitkan Pengumuman',
                                          style: TextStyle(
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
    hintStyle: const TextStyle(color: SigmaColors.textSub, fontSize: 13),
    filled: true,
    fillColor: SigmaColors.bgPage,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: SigmaColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: SigmaColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: SigmaColors.navy, width: 1.5),
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
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SigmaColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: SigmaColors.danger,
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
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: SigmaColors.bgPage,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SigmaColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: SigmaColors.textSub, fontSize: 13),
          ),
          isExpanded: true,
          dropdownColor: SigmaColors.white,
          style: const TextStyle(color: SigmaColors.navy, fontSize: 13),
          items: items
              .map(
                (e) =>
                    DropdownMenuItem<T>(value: e, child: Text(labelBuilder(e))),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
