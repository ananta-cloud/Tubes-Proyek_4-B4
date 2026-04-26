import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';

class ScheduleCreatePage extends StatefulWidget {
  final String idJurusan;
  const ScheduleCreatePage({super.key, required this.idJurusan});

  @override
  State<ScheduleCreatePage> createState() => _ScheduleCreatePageState();
}

class _ScheduleCreatePageState extends State<ScheduleCreatePage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedTipe = 'KULIAH';
  String? _selectedHari;
  final _ruanganCtrl = TextEditingController();
  final _dosenCtrl = TextEditingController();
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  // TODO: ganti dengan data dari MongoDB collection mata_kuliah
  final List<Map<String, String>> _masterMatkul = [
    {'id': '1', 'nama': 'Pemrograman Web Bergerak', 'kode': 'PWB'},
    {'id': '2', 'nama': 'Basis Data', 'kode': 'BD'},
  ];
  Map<String, String>? _selectedMatkul;

  bool _isSubmitting = false;

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_jamMulai == null || _jamSelesai == null) {
      _showSnack('Isi jam mulai dan jam selesai');
      return;
    }
    if (_selectedMatkul == null) {
      _showSnack('Pilih mata kuliah');
      return;
    }

    setState(() => _isSubmitting = true);

    final ctrl = context.read<ScheduleController>();
    final ok = await ctrl.createSchedule(
      idJurusan: widget.idJurusan,
      idProdi: '', // TODO: dari auth state
      idMk: _selectedMatkul!['id']!,
      namaMk: _selectedMatkul!['nama']!,
      kodeMk: _selectedMatkul!['kode']!,
      idPeriode: '2025-GENAP',
      tipe: _selectedTipe!,
      hari: _selectedHari!,
      jamMulai: _formatTime(_jamMulai!),
      jamSelesai: _formatTime(_jamSelesai!),
      ruangan: _ruanganCtrl.text,
      namaDosen: _dosenCtrl.text,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (ok) {
      _showSnack('Jadwal berhasil ditambahkan dengan status DRAFT');
      Navigator.pop(context);
    } else if (ctrl.collisionDetail != null) {
      _showCollisionDialog(ctrl.collisionDetail!);
    } else {
      _showSnack('Gagal menyimpan jadwal');
    }
  }

  void _showCollisionDialog(Map<String, dynamic> detail) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Collision Detected!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jadwal bentrok dengan:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow('Matkul', detail['nama_mk'] ?? '-'),
                  _DetailRow('Dosen', detail['nama_dosen'] ?? '-'),
                  _DetailRow('Ruangan', detail['ruangan'] ?? '-'),
                  _DetailRow(
                    'Waktu',
                    '${detail['hari']}, ${detail['jam_mulai']}–${detail['jam_selesai']}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan ubah waktu, ruangan, atau dosen.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo700,
            ),
            child: const Text(
              'Oke, Perbaiki',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Input Jadwal Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.indigo900,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Collision Detection Info ─────────────────
            _InfoCard(
              icon: Icons.shield,
              color: AppColors.indigo700,
              title: 'Collision Detection Aktif',
              body:
                  'Sistem otomatis cek bentrok berdasarkan ruangan, dosen, dan matkul saat kamu simpan.',
            ),
            const SizedBox(height: 16),

            // ── Form Card ────────────────────────────────
            _FormCard(
              children: [
                _SectionLabel('Mata Kuliah'),
                DropdownButtonFormField<Map<String, String>>(
                  decoration: _inputDecor('Pilih Mata Kuliah'),
                  items: _masterMatkul
                      .map(
                        (mk) => DropdownMenuItem(
                          value: mk,
                          child: Text(
                            '[${mk['kode']}] ${mk['nama']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMatkul = v),
                  validator: (v) => v == null ? 'Pilih mata kuliah' : null,
                ),
                const SizedBox(height: 14),

                _SectionLabel('Tipe Jadwal'),
                Row(
                  children: ['KULIAH', 'UTS', 'UAS'].map((t) {
                    final selected = _selectedTipe == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTipe = t),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.indigo700
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.indigo700
                                  : AppColors.slate200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              t,
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

                _SectionLabel('Hari'),
                DropdownButtonFormField<String>(
                  decoration: _inputDecor('Pilih Hari'),
                  items: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu']
                      .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedHari = v),
                  validator: (v) => v == null ? 'Pilih hari' : null,
                ),
                const SizedBox(height: 14),

                _SectionLabel('Jam Mulai & Selesai'),
                Row(
                  children: [
                    Expanded(
                      child: _TimePicker(
                        label: _jamMulai == null
                            ? 'Mulai'
                            : _formatTime(_jamMulai!),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 7, minute: 0),
                          );
                          if (t != null) setState(() => _jamMulai = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimePicker(
                        label: _jamSelesai == null
                            ? 'Selesai'
                            : _formatTime(_jamSelesai!),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (t != null) setState(() => _jamSelesai = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _SectionLabel('Ruangan'),
                TextFormField(
                  controller: _ruanganCtrl,
                  decoration: _inputDecor('Cth: GK-301, Lab RPL 2'),
                  validator: (v) => v!.isEmpty ? 'Isi ruangan' : null,
                ),
                const SizedBox(height: 14),

                _SectionLabel('Nama Dosen'),
                TextFormField(
                  controller: _dosenCtrl,
                  decoration: _inputDecor('Nama lengkap dosen pengampu'),
                  validator: (v) => v!.isEmpty ? 'Isi nama dosen' : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Status Info ──────────────────────────────
            _InfoCard(
              icon: Icons.info_outline,
              color: AppColors.slate500,
              title: 'Alur Status',
              body:
                  'DRAFT → (Finalisasi Admin TU) → FINAL → (Publikasi Admin TU) → PUBLISHED',
            ),

            const SizedBox(height: 20),

            // ── Submit ───────────────────────────────────
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSubmitting
                      ? 'Menyimpan...'
                      : 'Simpan Jadwal (Cek Collision)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
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
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ),
      ],
    ),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.slate600,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

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
      children: children,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
