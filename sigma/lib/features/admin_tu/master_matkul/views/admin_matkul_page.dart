import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main/views/admin_main_page.dart';
import '../viewmodels/admin_matkul_viewmodel.dart';
import '../models/matkul_model.dart';

class AdminMatkulPage extends StatefulWidget {
  const AdminMatkulPage({super.key});

  @override
  State<AdminMatkulPage> createState() => _AdminMatkulPageState();
}

class _AdminMatkulPageState extends State<AdminMatkulPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminMatkulViewModel>().fetchMatkul();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminMatkulViewModel>();

    return Scaffold(
      backgroundColor: SigmaColors.bgPage,
      body: Column(
        children: [
          // ── Header ──
          SigmaPageHeader(
            title: 'Master Matkul',
            action: SigmaPrimaryButton(
              label: 'Tambah',
              icon: Icons.add_rounded,
              onTap: () => _showMatkulForm(context, vm),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: SigmaColors.navy,
              onRefresh: () => vm.fetchMatkul(),
              child: CustomScrollView(
                slivers: [
                  // ── Section title ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.storage_rounded,
                            color: SigmaColors.navy,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Master Data Mata Kuliah',
                            style: TextStyle(
                              color: SigmaColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SigmaColors.navy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${vm.matkulList.length} MK',
                              style: const TextStyle(
                                color: SigmaColors.navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ──
                  if (vm.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: SigmaColors.navy,
                        ),
                      ),
                    )
                  else if (vm.matkulList.isEmpty)
                    SliverFillRemaining(
                      child: SigmaEmptyState(
                        icon: Icons.book_outlined,
                        message: 'Belum ada mata kuliah.',
                        sub: 'Tambah mata kuliah pertama →',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _MatkulCard(
                            matkul: vm.matkulList[i],
                            onEdit: () => _showMatkulForm(
                              context,
                              vm,
                              existing: vm.matkulList[i],
                            ),
                            onDelete: () =>
                                _confirmDelete(context, vm, vm.matkulList[i]),
                          ),
                          childCount: vm.matkulList.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete confirmation dialog ──
  void _confirmDelete(
    BuildContext context,
    AdminMatkulViewModel vm,
    MatkulModel matkul,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Mata Kuliah?',
          style: TextStyle(
            color: SigmaColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Yakin ingin menghapus "${matkul.namaMatkul}" (${matkul.kodeMk})?',
          style: const TextStyle(color: SigmaColors.textSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: SigmaColors.textSub),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await vm.deleteMatkul(matkul.id);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: SigmaColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit bottom sheet ──
  void _showMatkulForm(
    BuildContext context,
    AdminMatkulViewModel vm, {
    MatkulModel? existing,
  }) {
    // Pastikan prodiMap sudah terisi sebelum buka form
    if (vm.prodiMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data prodi belum dimuat, coba refresh halaman.'),
          backgroundColor: SigmaColors.danger,
        ),
      );
      return;
    }

    final kodeCtrl = TextEditingController(text: existing?.kodeMk ?? '');
    final namaCtrl = TextEditingController(text: existing?.namaMatkul ?? '');
    final sksCtrl = TextEditingController(
      text: existing != null ? '${existing.sks}' : '',
    );

    // Gunakan idProdi dari data existing, atau default ke key pertama prodiMap
    String selectedIdProdi = existing?.idProdi ?? vm.prodiMap.keys.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: SigmaColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SigmaColors.cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                existing == null ? 'Tambah Mata Kuliah' : 'Edit Mata Kuliah',
                style: const TextStyle(
                  color: SigmaColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),

              // Kode MK
              const _ModalFieldLabel(label: 'Kode MK', required: true),
              const SizedBox(height: 6),
              _modalTextField(kodeCtrl, 'Cth: IF302'),
              const SizedBox(height: 12),

              // Nama MK
              const _ModalFieldLabel(label: 'Nama Mata Kuliah', required: true),
              const SizedBox(height: 6),
              _modalTextField(namaCtrl, 'Cth: Basis Data'),
              const SizedBox(height: 12),

              // SKS + Program Studi
              Row(
                children: [
                  // SKS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _ModalFieldLabel(label: 'SKS', required: true),
                        const SizedBox(height: 6),
                        _modalTextField(
                          sksCtrl,
                          '3',
                          type: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Program Studi — dynamic dari prodiMap
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _ModalFieldLabel(label: 'Program Studi'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: SigmaColors.bgPage,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: SigmaColors.cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              // value harus ada di dalam items
                              value: vm.prodiMap.containsKey(selectedIdProdi)
                                  ? selectedIdProdi
                                  : vm.prodiMap.keys.first,
                              isExpanded: true,
                              style: const TextStyle(
                                color: SigmaColors.navy,
                                fontSize: 13,
                              ),
                              dropdownColor: SigmaColors.white,
                              // Build dari prodiMap: key=idHex, value=nama_prodi
                              items: vm.prodiMap.entries
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e.key, // ObjectId hex
                                      child: Text(e.value), // nama_prodi
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setModalState(
                                () => selectedIdProdi = v ?? selectedIdProdi,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    // Validasi input
                    if (kodeCtrl.text.trim().isEmpty ||
                        namaCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kode MK dan Nama tidak boleh kosong.'),
                          backgroundColor: SigmaColors.danger,
                        ),
                      );
                      return;
                    }
                    final sks = int.tryParse(sksCtrl.text.trim()) ?? 0;
                    if (sks <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SKS harus berupa angka lebih dari 0.'),
                          backgroundColor: SigmaColors.danger,
                        ),
                      );
                      return;
                    }

                    if (existing == null) {
                      await vm.addMatkul(
                        kodeMk: kodeCtrl.text.trim(),
                        namaMatkul: namaCtrl.text.trim(),
                        idProdi: selectedIdProdi,
                        sks: sks,
                      );
                    } else {
                      await vm.updateMatkul(
                        id: existing.id,
                        kodeMk: kodeCtrl.text.trim(),
                        namaMatkul: namaCtrl.text.trim(),
                        idProdi: selectedIdProdi,
                        sks: sks,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: SigmaColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        existing == null ? 'Tambah Matkul' : 'Simpan Perubahan',
                        style: const TextStyle(
                          color: SigmaColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalTextField(
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontSize: 14, color: SigmaColors.navy),
      decoration: InputDecoration(
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

// ─── Matkul Card ──────────────────────────────────────────────────────────────
class _MatkulCard extends StatelessWidget {
  const _MatkulCard({
    required this.matkul,
    required this.onEdit,
    required this.onDelete,
  });
  final MatkulModel matkul;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: SigmaColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SigmaColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Kode MK badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SigmaColors.navy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                matkul.kodeMk,
                style: const TextStyle(
                  color: SigmaColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nama + Program Studi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matkul.namaMatkul,
                    style: const TextStyle(
                      color: SigmaColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    matkul.programStudi, // nama_prodi hasil lookup
                    style: const TextStyle(
                      color: SigmaColors.textSub,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // SKS chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SigmaColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${matkul.sks} SKS',
                style: const TextStyle(
                  color: Color(0xFFB87A00),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Edit button
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SigmaColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: SigmaColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Delete button
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: SigmaColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: SigmaColors.danger,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modal Field Label ─────────────────────────────────────────────────────────
class _ModalFieldLabel extends StatelessWidget {
  const _ModalFieldLabel({required this.label, this.required = false});
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
