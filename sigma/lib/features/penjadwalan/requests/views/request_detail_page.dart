import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/theme/app_colors.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/features/penjadwalan/viewmodels/schedule_request_controller.dart';
import 'package:sigma/data/models/schedule_request_model.dart';

class RequestDetailPage extends StatelessWidget {
  final ScheduleRequestModel request;
  final UserModel user;
  final String idJurusan;

  const RequestDetailPage({
    super.key,
    required this.request,
    required this.user,
    required this.idJurusan,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<ScheduleRequestController>();

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Detail Request',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.indigo900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Info Dosen ───────────────────────
            _SectionCard(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.namaDosen,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            request.namaMk ?? '-',
                            style: TextStyle(
                              color: AppColors.indigo700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (request.kelas != null)
                            Text(
                              request.kelas!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.slate400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatusBadge(status: request.status),
                        if (request.isLate == true) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Text(
                              'TERLAMBAT',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: AppColors.slate100),
                const SizedBox(height: 10),

                // Tipe request
                _TipeBadge(tipe: request.tipeRequest),
                const SizedBox(height: 10),

                // Tanggal
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 13,
                      color: AppColors.slate400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      request.tanggalFormatted,
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Alasan Dosen ────────────────────────────
            _SectionLabel('ALASAN DOSEN'),
            const SizedBox(height: 6),
            _SectionCard(
              children: [
                Text(
                  request.alasan,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Perbandingan Jadwal ─────────────────────
            _SectionLabel('PERBANDINGAN PERUBAHAN'),
            const SizedBox(height: 6),

            // Jadwal saat ini
            _CompareCard(
              title: 'Jadwal Saat Ini',
              color: AppColors.slate500,
              hari: request.hariJadwal,
              jamMulai: request.jamMulaiJadwal,
              jamSelesai: request.jamSelesaiJadwal,
              ruangan: request.ruanganJadwal,
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Icon(
                  Icons.arrow_downward,
                  color: AppColors.indigo700,
                  size: 22,
                ),
              ),
            ),

            // Perubahan yang diminta
            _CompareCard(
              title: 'Perubahan yang Diminta',
              color: AppColors.indigo700,
              hari: request.detailPerubahan.hariBaru ?? request.hariJadwal,
              jamMulai:
                  request.detailPerubahan.jamMulaiBaru ??
                  request.jamMulaiJadwal,
              jamSelesai:
                  request.detailPerubahan.jamSelesaiBaru ??
                  request.jamSelesaiJadwal,
              ruangan:
                  request.detailPerubahan.ruanganBaru ?? request.ruanganJadwal,
              isNew: true,
              oldHari: request.hariJadwal,
              oldJamMulai: request.jamMulaiJadwal,
              oldJamSelesai: request.jamSelesaiJadwal,
              oldRuangan: request.ruanganJadwal,
            ),

            // ── Catatan Admin (jika sudah diproses) ─────
            if (request.catatanAdmin != null &&
                request.catatanAdmin!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionLabel('CATATAN TIM PENJADWALAN'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.indigo700.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.indigo700.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  request.catatanAdmin!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slate700,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Action Buttons (hanya jika PENDING) ─────
            if (request.isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context, ctrl),
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'TOLAK',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(context, ctrl),
                      icon: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'APPROVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Sudah diproses
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    Icon(
                      request.isApproved ? Icons.check_circle : Icons.cancel,
                      color: request.isApproved
                          ? AppColors.emerald700
                          : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.isApproved
                                ? 'Request Disetujui'
                                : 'Request Ditolak',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: request.isApproved
                                  ? AppColors.emerald700
                                  : Colors.red,
                            ),
                          ),
                          Text(
                            request.isApproved
                                ? 'Perubahan telah diterapkan ke jadwal.'
                                : 'Tidak ada perubahan pada jadwal.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(
    BuildContext context,
    ScheduleRequestController ctrl,
  ) {
    final catatanCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.emerald700),
            const SizedBox(width: 8),
            const Text(
              'Setujui Request',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Perubahan akan langsung diterapkan ke jadwal ${request.namaMk ?? ''}.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catatanCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Catatan (opsional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald700,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ctrl.approve(
                requestId: request.id,
                processorId: user.id,
                idJurusan: idJurusan,
                request: request,
                catatan: catatanCtrl.text.trim().isEmpty
                    ? null
                    : catatanCtrl.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Request disetujui & jadwal diperbarui'
                          : 'Gagal menyetujui request',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                if (ok) Navigator.pop(context);
              }
            },
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, ScheduleRequestController ctrl) {
    final catatanCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Tolak Request',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Berikan alasan penolakan agar dosen mengetahui tindak lanjutnya.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catatanCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan (wajib)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (catatanCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              final ok = await ctrl.reject(
                requestId: request.id,
                processorId: user.id,
                idJurusan: idJurusan,
                catatan: catatanCtrl.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Request ditolak' : 'Gagal menolak request',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                if (ok) Navigator.pop(context);
              }
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppColors.slate500,
      letterSpacing: 0.5,
    ),
  );
}

class _CompareCard extends StatelessWidget {
  final String title;
  final Color color;
  final String? hari;
  final String? jamMulai;
  final String? jamSelesai;
  final String? ruangan;
  final bool isNew;
  final String? oldHari;
  final String? oldJamMulai;
  final String? oldJamSelesai;
  final String? oldRuangan;

  const _CompareCard({
    required this.title,
    required this.color,
    this.hari,
    this.jamMulai,
    this.jamSelesai,
    this.ruangan,
    this.isNew = false,
    this.oldHari,
    this.oldJamMulai,
    this.oldJamSelesai,
    this.oldRuangan,
  });

  bool _changed(String? newVal, String? oldVal) =>
      isNew && newVal != null && newVal != oldVal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),

          // Hari & Jam
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: color),
              const SizedBox(width: 8),
              Text(
                '${hari ?? '-'}, ${jamMulai ?? '-'}–${jamSelesai ?? '-'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color:
                      _changed(hari, oldHari) || _changed(jamMulai, oldJamMulai)
                      ? color
                      : AppColors.slate800,
                ),
              ),
              if (_changed(hari, oldHari) ||
                  _changed(jamMulai, oldJamMulai)) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BERUBAH',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Ruangan
          Row(
            children: [
              Icon(Icons.room, size: 14, color: color),
              const SizedBox(width: 8),
              Text(
                ruangan ?? '-',
                style: TextStyle(
                  fontSize: 13,
                  color: _changed(ruangan, oldRuangan)
                      ? color
                      : AppColors.slate700,
                  fontWeight: _changed(ruangan, oldRuangan)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (_changed(ruangan, oldRuangan)) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BERUBAH',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TipeBadge extends StatelessWidget {
  final String tipe;
  const _TipeBadge({required this.tipe});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    IconData icon;
    switch (tipe) {
      case 'PINDAH_JAM':
        bg = const Color(0xFFF5F3FF);
        text = const Color(0xFF6D28D9);
        icon = Icons.access_time;
        break;
      case 'PINDAH_RUANGAN':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        icon = Icons.room;
        break;
      case 'KEDUANYA':
        bg = const Color(0xFFFFF7ED);
        text = const Color(0xFFC2410C);
        icon = Icons.swap_horiz;
        break;
      default:
        bg = AppColors.slate100;
        text = AppColors.slate600;
        icon = Icons.edit;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 5),
          Text(
            tipe.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    switch (status) {
      case 'APPROVED':
        bg = AppColors.emerald100;
        text = AppColors.emerald700;
        break;
      case 'REJECTED':
        bg = const Color(0xFFFEE2E2);
        text = Colors.red;
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
