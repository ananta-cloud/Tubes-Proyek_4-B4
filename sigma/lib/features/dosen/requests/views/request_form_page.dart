import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/theme/app_colors.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/features/dosen/requests/viewmodels/dosen_request_controller.dart';
import '../viewmodels/dosen_request_controller.dart';
import 'package:sigma/data/models/user_model.dart';

class RequestFormPage extends StatefulWidget {
  final UserModel user;
  const RequestFormPage({super.key, required this.user});

  @override
  State<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final _alasanCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Step: 0=pilih matkul, 1=pilih tipe+detail, 2=cek ruangan, 3=konfirmasi
  int _step = 0;

  final List<String> _hariOptions = [
    'SENIN',
    'SELASA',
    'RABU',
    'KAMIS',
    'JUMAT',
    'SABTU',
  ];

  @override
  void initState() {
    super.initState();
    _alasanCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<DosenRequestController>();
      ctrl.resetForm();
      if (widget.user.kodeDosen != null) {
        ctrl.loadMySchedules(widget.user.kodeDosen!);
      }
    });
  }

  @override
  void dispose() {
    _alasanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DosenRequestController>();

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Ajukan Perubahan Jadwal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF3F5DB3),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Step Indicator ─────────────────────────
            _StepIndicator(currentStep: _step, totalSteps: 4),
            const SizedBox(height: 20),

            // ── STEP 0: Pilih Mata Kuliah ───────────────
            if (_step == 0) ...[
              _SectionLabel('Pilih Mata Kuliah yang Diampu'),
              const SizedBox(height: 10),
              ctrl.isLoadingSchedules
                  ? const Center(child: CircularProgressIndicator())
                  : ctrl.mySchedules.isEmpty
                  ? _EmptyCard(
                      icon: Icons.calendar_today,
                      msg:
                          'Tidak ada jadwal ditemukan untuk kode dosen ${widget.user.kodeDosen}',
                    )
                  : Column(
                      children: ctrl.mySchedules.map((jadwal) {
                        final selected =
                            ctrl.selectedJadwal?['_id']?.toString() ==
                            jadwal['_id']?.toString();
                        return _JadwalCard(
                          jadwal: jadwal,
                          selected: selected,
                          onTap: () => ctrl.selectJadwal(jadwal),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 20),

              _NavBtn(
                label: 'Lanjut →',
                enabled: ctrl.selectedJadwal != null,
                onTap: () => setState(() => _step = 1),
              ),
            ],

            // ── STEP 1: Tipe + Detail Perubahan ────────
            if (_step == 1) ...[
              // Info jadwal terpilih
              _SelectedJadwalBanner(jadwal: ctrl.selectedJadwal!),
              const SizedBox(height: 16),

              _SectionLabel('Tipe Perubahan'),
              const SizedBox(height: 8),
              Row(
                children: ['PINDAH_JAM', 'PINDAH_RUANGAN', 'KEDUANYA'].map((t) {
                  final selected = ctrl.selectedTipeRequest == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ctrl.selectTipeRequest(t),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF3F5DB3)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF3F5DB3)
                                : AppColors.slate200,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            t.replaceAll('_', '\n'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : AppColors.slate600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Hari baru
              if (ctrl.selectedTipeRequest == 'PINDAH_JAM' ||
                  ctrl.selectedTipeRequest == 'KEDUANYA') ...[
                _SectionLabel('Hari Baru'),
                const SizedBox(height: 8),
                _DropdownField(
                  value: ctrl.selectedHariBaru,
                  items: _hariOptions,
                  hint: '-- Pilih Hari --',
                  onChanged: ctrl.selectHariBaru,
                ),
                const SizedBox(height: 14),

                _SectionLabel('Jam Baru'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TimePicker(
                        label: ctrl.selectedJamMulaiBaru ?? 'Jam Mulai',
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 7, minute: 0),
                          );
                          if (t != null) {
                            final mulai = _fmtTime(t);
                            final selesai = ctrl.selectedJamSelesaiBaru;
                            ctrl.selectJam(mulai, selesai ?? mulai);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimePicker(
                        label: ctrl.selectedJamSelesaiBaru ?? 'Jam Selesai',
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (t != null) {
                            final selesai = _fmtTime(t);
                            ctrl.selectJam(
                              ctrl.selectedJamMulaiBaru ?? selesai,
                              selesai,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tipe Jadwal TE/PR
                _SectionLabel('Tipe Jadwal'),
                const SizedBox(height: 8),
                Row(
                  children: ['TE', 'PR'].map((t) {
                    final selected = ctrl.selectedTipeJadwalBaru == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => ctrl.selectTipeJadwal(t),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF3F5DB3)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF3F5DB3)
                                  : AppColors.slate200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              t == 'TE' ? 'Teori' : 'Praktek',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.white
                                    : AppColors.slate600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ],

              // Alasan
              _SectionLabel('Alasan Permohonan'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _alasanCtrl,
                maxLines: 4,
                validator: (v) =>
                    v!.trim().length < 10 ? 'Alasan minimal 10 karakter' : null,
                decoration: InputDecoration(
                  hintText: 'Jelaskan alasan perubahan jadwal...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.slate200),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  _NavBtn(
                    label: '← Kembali',
                    onTap: () => setState(() => _step = 0),
                    secondary: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NavBtn(
                      label: 'Cek Ruangan →',
                      enabled:
                          ctrl.selectedTipeRequest != null &&
                          _alasanCtrl.text.trim().length >= 10,
                      onTap: () {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _step = 2);
                        // Auto-cek ruangan
                        if (ctrl.selectedHariBaru != null &&
                            ctrl.selectedJamMulaiBaru != null &&
                            ctrl.selectedJamSelesaiBaru != null) {
                          ctrl.checkRuangan(
                            hari: ctrl.selectedHariBaru!,
                            jamMulai: ctrl.selectedJamMulaiBaru!,
                            jamSelesai: ctrl.selectedJamSelesaiBaru!,
                            excludeScheduleId: ctrl.selectedJadwal!['_id']
                                .toHexString(),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],

            // ── STEP 2: Pilih Ruangan ───────────────────
            if (_step == 2) ...[
              _SelectedJadwalBanner(jadwal: ctrl.selectedJadwal!),
              const SizedBox(height: 16),

              // Info jadwal baru
              if (ctrl.selectedHariBaru != null)
                _InfoCard(
                  icon: Icons.access_time,
                  color: const Color(0xFF3F5DB3),
                  text:
                      '${ctrl.selectedHariBaru}, '
                      '${ctrl.selectedJamMulaiBaru}–${ctrl.selectedJamSelesaiBaru}',
                ),
              const SizedBox(height: 14),

              _SectionLabel('Ruangan Tersedia'),
              const SizedBox(height: 10),

              // Tombol cek manual (jika belum auto atau mau refresh)
              if (ctrl.selectedTipeRequest == 'PINDAH_RUANGAN')
                Column(
                  children: [
                    _SectionLabel('Hari & Jam untuk cek ruangan'),
                    const SizedBox(height: 8),
                    _DropdownField(
                      value: ctrl.selectedHariBaru,
                      items: _hariOptions,
                      hint: '-- Pilih Hari --',
                      onChanged: ctrl.selectHariBaru,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TimePicker(
                            label: ctrl.selectedJamMulaiBaru ?? 'Jam Mulai',
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(
                                  hour: 7,
                                  minute: 0,
                                ),
                              );
                              if (t != null)
                                ctrl.selectJam(
                                  _fmtTime(t),
                                  ctrl.selectedJamSelesaiBaru ?? _fmtTime(t),
                                );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimePicker(
                            label: ctrl.selectedJamSelesaiBaru ?? 'Jam Selesai',
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(
                                  hour: 9,
                                  minute: 0,
                                ),
                              );
                              if (t != null)
                                ctrl.selectJam(
                                  ctrl.selectedJamMulaiBaru ?? _fmtTime(t),
                                  _fmtTime(t),
                                );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            ctrl.selectedHariBaru != null &&
                                ctrl.selectedJamMulaiBaru != null
                            ? () => ctrl.checkRuangan(
                                hari: ctrl.selectedHariBaru!,
                                jamMulai: ctrl.selectedJamMulaiBaru!,
                                jamSelesai: ctrl.selectedJamSelesaiBaru!,
                                excludeScheduleId: ctrl.selectedJadwal!['_id']
                                    .toString(),
                              )
                            : null,
                        icon: const Icon(Icons.search),
                        label: const Text('Cek Ruangan Kosong'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3F5DB3),
                          side: const BorderSide(color: Color(0xFF3F5DB3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),

              ctrl.isCheckingRuangan
                  ? const Center(child: CircularProgressIndicator())
                  : ctrl.ruanganTersedia.isEmpty
                  ? _EmptyCard(
                      icon: Icons.room_outlined,
                      msg: ctrl.selectedHariBaru == null
                          ? 'Isi hari & jam terlebih dahulu lalu tekan Cek Ruangan'
                          : 'Tidak ada ruangan kosong di jam tersebut',
                    )
                  : Column(
                      children: ctrl.ruanganTersedia.map((ruangan) {
                        final selected = ctrl.selectedRuanganBaru == ruangan;
                        return GestureDetector(
                          onTap: () => ctrl.selectRuangan(ruangan),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF3F5DB3).withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF3F5DB3)
                                    : AppColors.slate200,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.room,
                                  size: 18,
                                  color: selected
                                      ? const Color(0xFF3F5DB3)
                                      : AppColors.slate400,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ruangan,
                                    style: TextStyle(
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: selected
                                          ? const Color(0xFF3F5DB3)
                                          : AppColors.slate700,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_circle,
                                    color: const Color(0xFF3F5DB3),
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

              const SizedBox(height: 20),
              Row(
                children: [
                  _NavBtn(
                    label: '← Kembali',
                    onTap: () => setState(() => _step = 1),
                    secondary: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NavBtn(
                      label: 'Review →',
                      enabled:
                          ctrl.selectedRuanganBaru != null ||
                          ctrl.selectedTipeRequest == 'PINDAH_JAM',
                      onTap: () => setState(() => _step = 3),
                    ),
                  ),
                ],
              ),
            ],

            // ── STEP 3: Review & Konfirmasi ─────────────
            if (_step == 3) ...[
              _SectionLabel('RINGKASAN PERMOHONAN'),
              const SizedBox(height: 10),

              _ReviewCard(ctrl: ctrl, alasan: _alasanCtrl.text),
              const SizedBox(height: 20),

              // Info peringatan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Request akan diproses oleh Tim Penjadwalan. '
                        'Jadwal baru berlaku setelah disetujui.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  _NavBtn(
                    label: '← Kembali',
                    onTap: () => setState(() => _step = 2),
                    secondary: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NavBtn(
                      label: ctrl.isSubmitting
                          ? 'Mengirim...'
                          : 'Kirim Permohonan ✓',
                      enabled: !ctrl.isSubmitting,
                      onTap: () async {
                        final ok = await ctrl.submitRequest(
                          idDosen: widget.user.id,
                          namaDosen: widget.user.nama,
                          alasan: _alasanCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Permohonan berhasil dikirim!'
                                  : 'Gagal mengirim permohonan',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        if (ok) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final labels = ['Pilih Matkul', 'Detail', 'Ruangan', 'Konfirmasi'];
    return Row(
      children: List.generate(totalSteps, (i) {
        final done = i < currentStep;
        final active = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done || active
                          ? const Color(0xFF3F5DB3)
                          : AppColors.slate200,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: active
                                    ? Colors.white
                                    : AppColors.slate500,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 9,
                      color: active
                          ? const Color(0xFF3F5DB3)
                          : AppColors.slate400,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (i < totalSteps - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: done ? const Color(0xFF3F5DB3) : AppColors.slate200,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final Map<String, dynamic> jadwal;
  final bool selected;
  final VoidCallback onTap;
  const _JadwalCard({
    required this.jadwal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF3F5DB3).withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF3F5DB3) : AppColors.slate200,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jadwal['nama_mk'] ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${jadwal['hari']} · ${jadwal['jam_mulai']}–${jadwal['jam_selesai']}',
                  style: TextStyle(fontSize: 12, color: AppColors.slate500),
                ),
                Text(
                  '${jadwal['ruangan']} · ${jadwal['kelas']}',
                  style: TextStyle(fontSize: 11, color: AppColors.slate400),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle, color: Color(0xFF3F5DB3), size: 20),
        ],
      ),
    ),
  );
}

class _SelectedJadwalBanner extends StatelessWidget {
  final Map<String, dynamic> jadwal;
  const _SelectedJadwalBanner({required this.jadwal});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF3F5DB3).withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF3F5DB3).withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.book, size: 16, color: const Color(0xFF3F5DB3)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jadwal['nama_mk'] ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF3F5DB3),
                ),
              ),
              Text(
                '${jadwal['hari']}, ${jadwal['jam_mulai']}–${jadwal['jam_selesai']} · ${jadwal['ruangan']}',
                style: TextStyle(fontSize: 11, color: AppColors.slate500),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  final DosenRequestController ctrl;
  final String alasan;
  const _ReviewCard({required this.ctrl, required this.alasan});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.slate200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewRow('Mata Kuliah', ctrl.selectedJadwal?['nama_mk'] ?? '-'),
        _ReviewRow('Kelas', ctrl.selectedJadwal?['kelas'] ?? '-'),
        _ReviewRow(
          'Tipe',
          ctrl.selectedTipeRequest?.replaceAll('_', ' ') ?? '-',
        ),
        const Divider(height: 20),
        _ReviewRow(
          'Jadwal Lama',
          '${ctrl.selectedJadwal?['hari']}, '
              '${ctrl.selectedJadwal?['jam_mulai']}–'
              '${ctrl.selectedJadwal?['jam_selesai']} · '
              '${ctrl.selectedJadwal?['ruangan']}',
        ),
        _ReviewRow(
          'Jadwal Baru',
          '${ctrl.selectedHariBaru ?? ctrl.selectedJadwal?['hari']}, '
              '${ctrl.selectedJamMulaiBaru ?? ctrl.selectedJadwal?['jam_mulai']}–'
              '${ctrl.selectedJamSelesaiBaru ?? ctrl.selectedJadwal?['jam_selesai']} · '
              '${ctrl.selectedRuanganBaru ?? ctrl.selectedJadwal?['ruangan']}',
        ),
        if (ctrl.selectedTipeJadwalBaru != null)
          _ReviewRow(
            'Tipe Jadwal',
            ctrl.selectedTipeJadwalBaru == 'TE' ? 'Teori' : 'Praktek',
          ),
        const Divider(height: 20),
        _ReviewRow('Alasan', alasan),
      ],
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String> onChanged;
  const _DropdownField({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.slate200),
      ),
    ),
    hint: Text(hint),
    items: items
        .map((h) => DropdownMenuItem(value: h, child: Text(h)))
        .toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

class _TimePicker extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimePicker({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 16, color: AppColors.slate400),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: AppColors.slate700, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _NavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool secondary;
  const _NavBtn({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: secondary
            ? Colors.white
            : enabled
            ? const Color(0xFF3F5DB3)
            : AppColors.slate200,
        borderRadius: BorderRadius.circular(12),
        border: secondary ? Border.all(color: AppColors.slate200) : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: secondary
                ? AppColors.slate600
                : enabled
                ? Colors.white
                : AppColors.slate400,
          ),
        ),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppColors.slate600,
      letterSpacing: 0.5,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String msg;
  const _EmptyCard({required this.icon, required this.msg});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.slate200),
    ),
    child: Column(
      children: [
        Icon(icon, size: 40, color: AppColors.slate300),
        const SizedBox(height: 10),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.slate500, fontSize: 13),
        ),
      ],
    ),
  );
}
