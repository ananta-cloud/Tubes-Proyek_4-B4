import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';
import '../../../../data/models/schedule_local_model.dart';

class ScheduleEditPage extends StatefulWidget {
  final ScheduleLocalModel jadwal;
  final String idJurusan;

  const ScheduleEditPage({
    super.key,
    required this.jadwal,
    required this.idJurusan,
  });

  @override
  State<ScheduleEditPage> createState() => _ScheduleEditPageState();
}

class _ScheduleEditPageState extends State<ScheduleEditPage> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedTipe;
  late String? _selectedHari;
  late TextEditingController _ruanganCtrl;
  late TextEditingController _dosenCtrl;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTipe = widget.jadwal.tipe;
    _selectedHari = widget.jadwal.hari;
    _ruanganCtrl = TextEditingController(text: widget.jadwal.ruangan);
    _dosenCtrl = TextEditingController(text: widget.jadwal.dosen);

    // Parse jam dari string HH:mm
    final mulaiParts = widget.jadwal.jamMulai.split(':');
    final selesaiParts = widget.jadwal.jamSelesai.split(':');
    _jamMulai = TimeOfDay(
      hour: int.parse(mulaiParts[0]),
      minute: int.parse(mulaiParts[1]),
    );
    _jamSelesai = TimeOfDay(
      hour: int.parse(selesaiParts[0]),
      minute: int.parse(selesaiParts[1]),
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final ctrl = context.read<ScheduleController>();
    final ok = await ctrl.updateSchedule(
      id: widget.jadwal.id,
      idJurusan: widget.idJurusan,
      namaMk: widget.jadwal.namaMk,
      tipe: _selectedTipe,
      hari: _selectedHari!,
      jamMulai: _formatTime(_jamMulai!),
      jamSelesai: _formatTime(_jamSelesai!),
      ruangan: _ruanganCtrl.text,
      namaDosen: _dosenCtrl.text,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal diperbarui. Status direset ke DRAFT.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else if (ctrl.collisionDetail != null) {
      _showCollisionDialog(ctrl.collisionDetail!);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal memperbarui jadwal')));
    }
  }

  void _showCollisionDialog(Map<String, dynamic> detail) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Collision Detected!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perubahan menyebabkan bentrok dengan:',
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
                  _DetailRow('Status', detail['status'] ?? '-'),
                ],
              ),
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
              'Perbaiki',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Edit Jadwal',
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
            // ── Warning ──────────────────────────────────
            _InfoCard(
              icon: Icons.warning_amber,
              color: const Color(0xFFD97706),
              title: 'Perhatian',
              body:
                  'Setiap perubahan akan mereset status jadwal kembali ke DRAFT dan harus melalui finalisasi ulang.',
            ),
            const SizedBox(height: 16),

            // ── Info Matkul (Read-only) ───────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mata Kuliah (Tidak dapat diubah)',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.slate400,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.jadwal.namaMk,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${widget.jadwal.kodeMk} · ${widget.jadwal.dosen}',
                    style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Form ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    value: _selectedHari,
                    decoration: _inputDecor('Pilih Hari'),
                    items:
                        ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu']
                            .map(
                              (h) => DropdownMenuItem(value: h, child: Text(h)),
                            )
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
                              initialTime: _jamMulai!,
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
                              initialTime: _jamSelesai!,
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
            ),

            // ── Data Saat Ini ─────────────────────────────
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, size: 14, color: AppColors.slate400),
                      const SizedBox(width: 6),
                      Text(
                        'Data Saat Ini',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _CurrentDataRow('Hari', widget.jadwal.hari),
                  _CurrentDataRow(
                    'Jam',
                    '${widget.jadwal.jamMulai}–${widget.jadwal.jamSelesai}',
                  ),
                  _CurrentDataRow('Ruangan', widget.jadwal.ruangan),
                  _CurrentDataRow('Dosen', widget.jadwal.dosen),
                  _CurrentDataRow('Status', widget.jadwal.status),
                ],
              ),
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
                      : 'Simpan Perubahan (Cek Collision)',
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

class _CurrentDataRow extends StatelessWidget {
  final String label;
  final String value;
  const _CurrentDataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.slate400)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
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
