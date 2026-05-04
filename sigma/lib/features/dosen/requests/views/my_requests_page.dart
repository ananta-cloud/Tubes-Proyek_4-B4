import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/theme/app_colors.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/features/dosen/requests/viewmodels/dosen_request_controller.dart';
import 'package:sigma/features/penjadwalan/viewmodels/schedule_request_controller.dart';
import 'package:sigma/data/models/schedule_request_model.dart';

class MyRequestsPage extends StatefulWidget {
  final UserModel user;
  const MyRequestsPage({super.key, required this.user});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DosenRequestController>().loadMyRequests(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DosenRequestController>();

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Riwayat Permohonan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF3F5DB3),
        foregroundColor: Colors.white,
      ),
      body: ctrl.isLoadingRequests
          ? const Center(child: CircularProgressIndicator())
          : ctrl.myRequests.isEmpty
          ? _EmptyState()
          : RefreshIndicator(
              onRefresh: () => ctrl.loadMyRequests(widget.user.id),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: ctrl.myRequests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _RequestCard(
                  request: ctrl.myRequests[i],
                  onCancel: ctrl.myRequests[i].isPending
                      ? () => _confirmCancel(context, ctrl, ctrl.myRequests[i])
                      : null,
                ),
              ),
            ),
    );
  }

  void _confirmCancel(
    BuildContext context,
    DosenRequestController ctrl,
    ScheduleRequestModel req,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Batalkan Permohonan?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Permohonan untuk ${req.namaMk ?? '-'} akan dibatalkan.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ctrl.cancelRequest(req.id, widget.user.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Permohonan dibatalkan' : 'Gagal membatalkan',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Request Card ──────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final ScheduleRequestModel request;
  final VoidCallback? onCancel;

  const _RequestCard({required this.request, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: request.isLate == true
              ? Colors.red.shade100
              : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.namaMk ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.kelas ?? '-',
                      style: TextStyle(fontSize: 11, color: AppColors.slate400),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),

          const SizedBox(height: 8),
          Divider(color: AppColors.slate100, height: 1),
          const SizedBox(height: 8),

          // ── Perbandingan ringkas ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'JADWAL LAMA',
                  value:
                      '${request.hariJadwal ?? '-'}\n'
                      '${request.jamMulaiJadwal ?? '-'}–'
                      '${request.jamSelesaiJadwal ?? '-'}\n'
                      '${request.ruanganJadwal ?? '-'}',
                  color: AppColors.slate500,
                ),
              ),
              Icon(Icons.arrow_forward, size: 16, color: AppColors.slate300),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniInfo(
                  label: 'PERUBAHAN',
                  value:
                      '${request.detailPerubahan.hariBaru ?? request.hariJadwal ?? '-'}\n'
                      '${request.detailPerubahan.jamMulaiBaru ?? request.jamMulaiJadwal ?? '-'}–'
                      '${request.detailPerubahan.jamSelesaiBaru ?? request.jamSelesaiJadwal ?? '-'}\n'
                      '${request.detailPerubahan.ruanganBaru ?? request.ruanganJadwal ?? '-'}',
                  color: const Color(0xFF3F5DB3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _TipeBadge(tipe: request.tipeRequest),
          const SizedBox(height: 6),

          // ── Alasan ───────────────────────────────────
          Text(
            request.alasan,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.slate600),
          ),

          const SizedBox(height: 6),
          Text(
            request.tanggalFormatted,
            style: TextStyle(fontSize: 10, color: AppColors.slate400),
          ),

          // ── Catatan admin jika sudah diproses ─────────
          if (request.catatanAdmin != null &&
              request.catatanAdmin!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: request.isApproved
                    ? AppColors.emerald100.withOpacity(0.5)
                    : const Color(0xFFFEE2E2).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Tim Penjadwalan:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: request.isApproved
                          ? AppColors.emerald700
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    request.catatanAdmin!,
                    style: TextStyle(
                      fontSize: 12,
                      color: request.isApproved
                          ? AppColors.emerald700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Tombol batal jika PENDING ─────────────────
          if (onCancel != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Batalkan Permohonan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],

          if (request.isLate == true) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.warning_amber, size: 13, color: Colors.red.shade400),
                const SizedBox(width: 4),
                Text(
                  'Diajukan setelah periode revisi berakhir',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sub widgets ───────────────────────────────────────────

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 11, color: color, height: 1.5)),
    ],
  );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: text),
          const SizedBox(width: 4),
          Text(
            tipe.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history, size: 52, color: AppColors.slate300),
        const SizedBox(height: 12),
        Text(
          'Belum ada permohonan',
          style: TextStyle(
            color: AppColors.slate500,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Permohonan yang kamu ajukan akan muncul di sini',
          style: TextStyle(color: AppColors.slate400, fontSize: 12),
        ),
      ],
    ),
  );
}
