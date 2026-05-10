import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/theme/app_colors.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/features/dosen/requests/viewmodels/dosen_request_controller.dart';
import 'package:intl/intl.dart';

class RequestFormPage extends StatefulWidget {
  final UserModel user;
  const RequestFormPage({super.key, required this.user});

  @override
  State<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final _alasanCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _alasanCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DosenRequestController>().loadMySchedules(
        widget.user.kodeDosen ?? '',
      );
    });
  }

  String _fmtTime(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DosenRequestController>();

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Buat Permohonan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF3F5DB3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepper(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_step == 0) ..._buildStep0(ctrl),
                    if (_step == 1) ..._buildStep1(ctrl),
                    if (_step == 2) ..._buildStep2(ctrl),
                    if (_step == 3) ..._buildStep3(ctrl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 0: PILIH JADWAL ──────────────────
  List<Widget> _buildStep0(DosenRequestController ctrl) {
    return [
      const _SectionLabel('Pilih Mata Kuliah yang Ingin Diubah'),
      const SizedBox(height: 12),
      if (ctrl.isLoadingSchedules)
        const Center(child: CircularProgressIndicator())
      else if (ctrl.mySchedules.isEmpty)
        const _EmptyCard(icon: Icons.event_busy, msg: 'Jadwal tidak ditemukan')
      else
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ctrl.mySchedules.length,
          itemBuilder: (context, index) {
            final s = ctrl.mySchedules[index];
            final isSelected = ctrl.selectedJadwal?['_id'] == s['_id'];
            return GestureDetector(
              onTap: () => ctrl.selectJadwal(s),
              child: _JadwalCard(jadwal: s, isSelected: isSelected),
            );
          },
        ),
      const SizedBox(height: 24),
      if (ctrl.selectedJadwal != null)
        _NavBtn(label: 'Lanjut →', onTap: () => setState(() => _step = 1)),
    ];
  }

  // ── STEP 1: PILIH TANGGAL & WAKTU ─────────────────────────────────────
  List<Widget> _buildStep1(DosenRequestController ctrl) {
    return [
      if (ctrl.selectedJadwal != null)
        _SelectedJadwalBanner(jadwal: ctrl.selectedJadwal!),
      const SizedBox(height: 20),
      const _SectionLabel('Rencana Waktu Baru'),
      const SizedBox(height: 12),
      _InputTile(
        label: ctrl.selectedTanggalBaru == null
            ? 'Pilih Tanggal Baru'
            : DateFormat(
                'EEEE, dd MMMM yyyy',
                'id_ID',
              ).format(ctrl.selectedTanggalBaru!),
        icon: Icons.calendar_month,
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 60)),
          );
          if (d != null) ctrl.selectTanggal(d);
        },
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _InputTile(
              label: ctrl.selectedJamMulaiBaru ?? 'Jam Mulai',
              icon: Icons.access_time,
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 7, minute: 0),
                );
                if (t != null)
                  ctrl.selectJam(
                    _fmtTime(t),
                    ctrl.selectedJamSelesaiBaru ?? _fmtTime(t),
                  );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InputTile(
              label: ctrl.selectedJamSelesaiBaru ?? 'Jam Selesai',
              icon: Icons.access_time,
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 9, minute: 0),
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
      const SizedBox(height: 24),
      _NavBtn(
        label: 'Cek Ruangan →',
        enabled: ctrl.selectedTanggalBaru != null,
        onTap: () {
          ctrl.checkRuangan(
            excludeScheduleId: ctrl.selectedJadwal!['_id'].toString(),
          );
          setState(() => _step = 2);
        },
      ),
      _NavBtn(
        label: '← Kembali',
        secondary: true,
        onTap: () => setState(() => _step = 0),
      ),
    ];
  }

  // ── STEP 2: PILIH RUANGAN ─────────────────────────────────────────────
  List<Widget> _buildStep2(DosenRequestController ctrl) {
    return [
      if (ctrl.selectedJadwal != null)
        _SelectedJadwalBanner(jadwal: ctrl.selectedJadwal!),
      const SizedBox(height: 12),

      if (ctrl.autoTipeRequest != null)
        _InfoCard(
          icon: Icons.info_outline,
          color: const Color(0xFF3F5DB3),
          text:
              "Tipe: ${ctrl.autoTipeRequest == 'PINDAH_RUANGAN' ? 'Hanya Pindah Ruangan' : 'Pindah Jam & Ruangan'}",
        ),

      const SizedBox(height: 20),
      const _SectionLabel('Pilih Ruangan Tersedia'),
      const SizedBox(height: 12),

      if (ctrl.isCheckingRuangan)
        const Center(child: CircularProgressIndicator())
      else ...[
        // List Ruangan
        ...ctrl.ruanganTersedia.map(
          (r) => GestureDetector(
            onTap: () => ctrl.selectRuangan(r),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ctrl.selectedRuanganBaru == r
                    ? const Color(0xFF3F5DB3).withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ctrl.selectedRuanganBaru == r
                      ? const Color(0xFF3F5DB3)
                      : AppColors.slate200,
                  width: ctrl.selectedRuanganBaru == r ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.room,
                    size: 20,
                    color: ctrl.selectedRuanganBaru == r
                        ? const Color(0xFF3F5DB3)
                        : AppColors.slate400,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    r,
                    style: TextStyle(
                      fontWeight: ctrl.selectedRuanganBaru == r
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (ctrl.selectedRuanganBaru == r)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF3F5DB3),
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
        const _SectionLabel('Alasan Perubahan'),
        const SizedBox(height: 10),
        TextFormField(
          controller: _alasanCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Tuliskan alasan permohonan...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Alasan wajib diisi' : null,
        ),
      ],

      const SizedBox(height: 24),
      if (ctrl.isSubmitting)
        const Center(child: CircularProgressIndicator())
      else
        _NavBtn(
          label: 'Review Permohonan →',
          enabled:
              ctrl.selectedRuanganBaru != null && _alasanCtrl.text.isNotEmpty,
          onTap: () {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _step = 3);
          },
        ),
      _NavBtn(
        label: '← Kembali',
        secondary: true,
        onTap: () => setState(() => _step = 1),
      ),
    ];
  }

  // ── STEP 3: RINGKASAN ───────────────────────────────────────────────────
  List<Widget> _buildStep3(DosenRequestController ctrl) {
    if (ctrl.selectedJadwal == null) {
      return [
        const Center(child: Text("Data tidak ditemukan, silakan kembali.")),
      ];
    }
    final lama = ctrl.selectedJadwal!;
    final tglBaru = ctrl.selectedTanggalBaru != null
        ? DateFormat(
            'EEEE, dd MMMM yyyy',
            'id_ID',
          ).format(ctrl.selectedTanggalBaru!)
        : '-';

    return [
      const _SectionLabel('Ringkasan Perubahan'),
      const SizedBox(height: 16),

      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Column(
          children: [
            _buildSummaryRow("Mata Kuliah", lama['nama_mk'] ?? '-'),
            const Divider(height: 24),
            _buildSummaryRow(
              "Jadwal Asli",
              "${lama['hari']}, ${lama['jam_mulai']} - ${lama['jam_selesai']}",
            ),
            _buildSummaryRow("Ruangan Asli", lama['ruangan'] ?? '-'),
            const Divider(height: 24),
            _buildSummaryRow(
              "Jadwal Baru",
              "$tglBaru\n${ctrl.selectedJamMulaiBaru} - ${ctrl.selectedJamSelesaiBaru}",
              isNew: true,
            ),
            _buildSummaryRow(
              "Ruangan Baru",
              ctrl.selectedRuanganBaru ?? '-',
              isNew: true,
            ),
            const Divider(height: 24),
            _buildSummaryRow("Alasan", _alasanCtrl.text),
          ],
        ),
      ),

      const SizedBox(height: 32),
      if (ctrl.isSubmitting)
        const Center(child: CircularProgressIndicator())
      else
        _NavBtn(
          label: 'Konfirmasi & Kirim',
          onTap: () async {
            final ok = await ctrl.submitRequest(
              idDosen: widget.user.id,
              namaDosen: widget.user.nama,
              alasan: _alasanCtrl.text,
            );

            if (ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permohonan berhasil dikirim!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
          },
        ),
      _NavBtn(
        label: '← Ubah Data',
        secondary: true,
        onTap: () => setState(() => _step = 2),
      ),
    ];
  }

  // Widget Ringkasan
  Widget _buildSummaryRow(String label, String value, {bool isNew = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: AppColors.slate500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isNew ? const Color(0xFF3F5DB3) : Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final stepLabels = ['Jadwal', 'Waktu & Ruang', 'Selesai'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: List.generate(stepLabels.length, (index) {
                final isDone = _step > index;
                final isCurrent = _step == index;

                return Expanded(
                  flex: index == stepLabels.length - 1 ? 0 : 1,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone || isCurrent
                              ? const Color(0xFF3F5DB3)
                              : const Color(0xFFE2E8F0),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                      if (index < stepLabels.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isDone
                                ? const Color(0xFF3F5DB3)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stepLabels.length, (index) {
                final isCurrent = _step == index;
                return SizedBox(
                  width: 60,
                  child: Text(
                    stepLabels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? const Color(0xFF3F5DB3)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM COMPONENTS ────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1E293B),
    ),
  );
}

class _InputTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _InputTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF3F5DB3)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary ? Colors.white : const Color(0xFF3F5DB3),
          foregroundColor: secondary ? const Color(0xFF3F5DB3) : Colors.white,
          elevation: 0,
          side: secondary ? const BorderSide(color: Color(0xFF3F5DB3)) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    ),
  );
}

class _JadwalCard extends StatelessWidget {
  final Map<String, dynamic> jadwal;
  final bool isSelected;
  const _JadwalCard({required this.jadwal, required this.isSelected});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSelected ? const Color(0xFF3F5DB3) : AppColors.slate200,
        width: isSelected ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          jadwal['nama_mk'] ?? '-',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: AppColors.slate400),
            const SizedBox(width: 6),
            Text(
              '${jadwal['hari']}, ${jadwal['jam_mulai']} - ${jadwal['jam_selesai']}',
              style: TextStyle(color: AppColors.slate500, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.room, size: 14, color: AppColors.slate400),
            const SizedBox(width: 6),
            Text(
              jadwal['ruangan'] ?? '-',
              style: TextStyle(color: AppColors.slate500, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SelectedJadwalBanner extends StatelessWidget {
  final Map<String, dynamic> jadwal;
  const _SelectedJadwalBanner({required this.jadwal});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF3F5DB3).withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF3F5DB3).withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.book, size: 16, color: const Color(0xFF3F5DB3)),
            const SizedBox(width: 8),
            const Text(
              "Informasi Jadwal Asli",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF3F5DB3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          jadwal['nama_mk'] ?? '-',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${jadwal['hari']}, ${jadwal['jam_mulai']} - ${jadwal['jam_selesai']} | ${jadwal['ruangan']}',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF3F5DB3),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.slate300),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: AppColors.slate500)),
        ],
      ),
    ),
  );
}
