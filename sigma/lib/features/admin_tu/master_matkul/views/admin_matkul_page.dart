import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main/views/admin_main_page.dart';
import '../viewmodels/admin_matkul_viewmodel.dart';
import '../../../../data/models/matkul_model.dart';

class AdminMatkulPage extends StatefulWidget {
  const AdminMatkulPage({super.key});

  @override
  State<AdminMatkulPage> createState() => _AdminMatkulPageState();
}

class _AdminMatkulPageState extends State<AdminMatkulPage> {
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminMatkulViewModel>().fetchMatkul();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) context.read<AdminMatkulViewModel>().fetchMatkul();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminMatkulViewModel>();

    return Scaffold(
      backgroundColor: SigmaColors.bgPage,
      body: Column(
        children: [
          SigmaPageHeader(
            title: 'Master Matkul',
            action: SigmaPrimaryButton(
              label: 'Tambah',
              icon: Icons.add_rounded,
              onTap: () => _showMatkulForm(context, vm),
            ),
          ),

          _SyncStatusBanner(
            status: vm.syncStatus,
            pendingCount: vm.pendingMatkulCount,
          ),

          Expanded(
            child: RefreshIndicator(
              color: SigmaColors.navy,
              onRefresh: () => vm.fetchMatkul(),
              child: CustomScrollView(
                slivers: [
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

                  if (vm.isLoading && vm.matkulList.isEmpty)
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
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final matkul = vm.matkulList[i];
                          final isPending = vm.isMatkulPending(matkul.id);
                          return _MatkulCard(
                            matkul: matkul,
                            isPending: isPending,
                            onEdit: () =>
                                _showMatkulForm(context, vm, existing: matkul),
                            onDelete: () => _confirmDelete(context, vm, matkul),
                          );
                        }, childCount: vm.matkulList.length),
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

  void _showMatkulForm(
    BuildContext context,
    AdminMatkulViewModel vm, {
    MatkulModel? existing,
  }) {
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
              const _ModalFieldLabel(label: 'Kode MK', required: true),
              const SizedBox(height: 6),
              _modalTextField(kodeCtrl, 'Cth: IF302'),
              const SizedBox(height: 12),
              const _ModalFieldLabel(label: 'Nama Mata Kuliah', required: true),
              const SizedBox(height: 6),
              _modalTextField(namaCtrl, 'Cth: Basis Data'),
              const SizedBox(height: 12),
              Row(
                children: [
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
                              value: vm.prodiMap.containsKey(selectedIdProdi)
                                  ? selectedIdProdi
                                  : vm.prodiMap.keys.first,
                              isExpanded: true,
                              style: const TextStyle(
                                color: SigmaColors.navy,
                                fontSize: 13,
                              ),
                              dropdownColor: SigmaColors.white,
                              items: vm.prodiMap.entries
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e.key,
                                      child: Text(e.value),
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
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
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

// ─────────────────────────────────────────────────────────────────────────────
//  Sync Status Banner
// ─────────────────────────────────────────────────────────────────────────────
class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({required this.status, required this.pendingCount});

  final SyncStatus status;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.idle) return const SizedBox.shrink();

    final (Color bg, Color fg, IconData icon, String text) = switch (status) {
      SyncStatus.pending => (
        const Color(0xFFFFF3CD),
        const Color(0xFFB45309),
        Icons.cloud_off_rounded,
        '$pendingCount matkul tersimpan lokal — belum terkirim ke server',
      ),
      SyncStatus.syncing => (
        SigmaColors.navy.withValues(alpha: 0.08),
        SigmaColors.navy,
        Icons.sync_rounded,
        'Mengirim $pendingCount matkul ke server...',
      ),
      SyncStatus.synced => (
        const Color(0xFFE8F5E9),
        SigmaColors.success,
        Icons.cloud_done_rounded,
        'Semua matkul berhasil tersimpan ke server',
      ),
      SyncStatus.failed => (
        SigmaColors.danger.withValues(alpha: 0.08),
        SigmaColors.danger,
        Icons.cloud_off_rounded,
        'Gagal mengirim ke server — akan dicoba ulang saat online',
      ),
      SyncStatus.idle => (
        Colors.transparent,
        Colors.transparent,
        Icons.check,
        '',
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bg,
      child: Row(
        children: [
          status == SyncStatus.syncing
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Icon(icon, color: fg, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Matkul Card
// ─────────────────────────────────────────────────────────────────────────────
class _MatkulCard extends StatelessWidget {
  const _MatkulCard({
    required this.matkul,
    required this.isPending,
    required this.onEdit,
    required this.onDelete,
  });

  final MatkulModel matkul;
  final bool isPending;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: SigmaColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? const Color(0xFFB45309).withValues(alpha: 0.3)
              : SigmaColors.cardBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Baris 1: kode MK (kiri) + SKS badge + sync icon (kanan) ──
            // FIX: Row dengan mainAxisAlignment spaceBetween agar
            // badge SKS & sync icon SELALU menempel di kanan,
            // tidak peduli panjang kode MK
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Kode MK — Flexible agar bisa ellipsis jika terlalu panjang
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Badge SKS + sync icon selalu di kanan, tidak ikut wrap
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                    const SizedBox(width: 6),
                    Tooltip(
                      message: isPending
                          ? 'Belum terkirim ke server'
                          : 'Sudah di server',
                      child: Icon(
                        isPending
                            ? Icons.cloud_off_rounded
                            : Icons.cloud_done_rounded,
                        size: 14,
                        color: isPending
                            ? const Color(0xFFB45309)
                            : SigmaColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Baris 2: Nama MK — wrap bebas ────────────────────────
            Text(
              matkul.namaMatkul,
              style: const TextStyle(
                color: SigmaColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              softWrap: true,
            ),

            const SizedBox(height: 2),

            // ── Baris 3: Program Studi ────────────────────────────────
            Text(
              matkul.programStudi,
              style: const TextStyle(color: SigmaColors.textSub, fontSize: 11),
              softWrap: true,
            ),

            const SizedBox(height: 10),

            // ── Baris 4: tombol Edit + Delete selalu rata kanan ───────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
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
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Modal Field Label
// ─────────────────────────────────────────────────────────────────────────────
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
//new