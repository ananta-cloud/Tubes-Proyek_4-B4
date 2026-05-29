import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/shared/app_colors.dart';

import '../../main/views/admin_main_page.dart';
import '../viewmodels/admin_matkul_viewmodel.dart';
import '../../../../data/models/matkul_model.dart';
import 'package:sigma/shared/widgets/page_header.dart';
import 'package:sigma/shared/widgets/primary_button.dart';
import '../widgets/matkul_sync_banner.dart';
import '../widgets/matkul_card.dart';
import '../widgets/modal_field_label.dart';

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
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          PageHeader(
            title: 'Master Matkul',
            action: PrimaryButton(
              label: 'Tambah',
              icon: Icons.add_rounded,
              onTap: () => _showMatkulForm(context, vm),
            ),
          ),

          SyncStatusBanner(
            status: vm.syncStatus,
            pendingCount: vm.pendingMatkulCount,
          ),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.navy,
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
                            color: AppColors.navy,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Master Data Mata Kuliah',
                            style: TextStyle(
                              color: AppColors.navy,
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
                              color: AppColors.navy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${vm.matkulList.length} MK',
                              style: const TextStyle(
                                color: AppColors.navy,
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
                        child: CircularProgressIndicator(color: AppColors.navy),
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
                          return MatkulCard(
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
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Yakin ingin menghapus "${matkul.namaMatkul}" (${matkul.kodeMk})?',
          style: const TextStyle(color: AppColors.textSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSub),
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
                color: AppColors.danger,
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
          backgroundColor: AppColors.danger,
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
            color: AppColors.white,
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
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                existing == null ? 'Tambah Mata Kuliah' : 'Edit Mata Kuliah',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const ModalFieldLabel(label: 'Kode MK', required: true),
              const SizedBox(height: 6),
              _modalTextField(kodeCtrl, 'Cth: IF302'),
              const SizedBox(height: 12),
              const ModalFieldLabel(label: 'Nama Mata Kuliah', required: true),
              const SizedBox(height: 6),
              _modalTextField(namaCtrl, 'Cth: Basis Data'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ModalFieldLabel(label: 'SKS', required: true),
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
                        const ModalFieldLabel(label: 'Program Studi'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.bgPage,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: vm.prodiMap.containsKey(selectedIdProdi)
                                  ? selectedIdProdi
                                  : vm.prodiMap.keys.first,
                              isExpanded: true,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 13,
                              ),
                              dropdownColor: AppColors.white,
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
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }
                    final sks = int.tryParse(sksCtrl.text.trim()) ?? 0;
                    if (sks <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SKS harus berupa angka lebih dari 0.'),
                          backgroundColor: AppColors.danger,
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
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        existing == null ? 'Tambah Matkul' : 'Simpan Perubahan',
                        style: const TextStyle(
                          color: AppColors.white,
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
      style: const TextStyle(fontSize: 14, color: AppColors.navy),
      decoration: InputDecoration(
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
