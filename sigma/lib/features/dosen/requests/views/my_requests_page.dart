import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/shared/app_colors.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/data/models/schedule_request_model.dart';
import 'package:sigma/features/dosen/requests/viewmodels/dosen_request_controller.dart';
import '../views/request_form_page.dart';
import 'package:sigma/data/models/dosen_model.dart';
import 'package:sigma/shared/widgets/offline_banner.dart';
import '../widgets/pending_requests_card.dart';
import 'package:sigma/shared/widgets/section_header.dart';

class MyRequestsPage extends StatefulWidget {
  final UserModel user;
  final DosenModel dosen;
  final bool isActive;
  const MyRequestsPage({
    super.key,
    required this.user,
    required this.dosen,
    required this.isActive,
  });

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DosenRequestController>().loadMyRequests(
          widget.dosen.id,
          forceRefresh: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DosenRequestController>();
    final cancelIds = ctrl.cancelQueueIds;
    if (ctrl.justSynced && widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text('Semua permohonan berhasil tersinkronisasi'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          ctrl.clearSyncFlag();
        }
      });
    }
    final isEmpty =
        ctrl.myRequests.isEmpty &&
        ctrl.pendingRequests.isEmpty &&
        cancelIds.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Riwayat Permohonan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1F3D),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ctrl.isLoadingRequests
          ? const Center(child: CircularProgressIndicator())
          : isEmpty
          ? const _EmptyState()
          : RefreshIndicator(
              onRefresh: () => ctrl.loadMyRequests(widget.dosen.id),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (ctrl.isOffline) const OfflineBanner(),

                  if (ctrl.pendingRequests.isNotEmpty) ...[
                    const SectionHeader(
                      label: 'Menunggu Terkirim',
                      icon: Icons.cloud_upload_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    ...ctrl.pendingRequests.map(
                      (data) => PendingRequestCard(data: data),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (ctrl.myRequests.isNotEmpty) ...[
                    const SectionHeader(
                      label: 'Riwayat Server',
                      icon: Icons.history,
                      color: Color(0xFF3F5DB3),
                    ),
                    const SizedBox(height: 8),
                    ...ctrl.myRequests.map((req) {
                      final willBeDeleted = cancelIds.contains(req.id);
                      return _RequestCard(
                        request: req,
                        willBeDeleted: willBeDeleted,
                        onCancel: req.isPending && !willBeDeleted
                            ? () => _confirmCancel(context, ctrl, req)
                            : null,
                      );
                    }),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_my_requests',
        onPressed: () => _goToForm(context),
        backgroundColor: const Color(0xFF3F5DB3),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Buat Permohonan',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _confirmCancel(
    BuildContext context,
    DosenRequestController ctrl,
    ScheduleRequestModel req,
  ) {
    final isOffline = ctrl.isOffline;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Batalkan Permohonan?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permohonan untuk ${req.namaMk ?? '-'} akan dibatalkan.',
              style: const TextStyle(fontSize: 13),
            ),
            if (isOffline) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 14,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kamu sedang offline. Pembatalan akan diproses saat koneksi tersedia.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
              final ok = await ctrl.cancelRequest(req.id, widget.dosen.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? isOffline
                                ? 'Akan dibatalkan setelah online'
                                : 'Permohonan dibatalkan'
                          : 'Gagal membatalkan',
                    ),
                    backgroundColor: ok && isOffline ? Colors.orange : null,
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

  void _goToForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestFormPage(dosen: widget.dosen, user: widget.user),
      ),
    ).then((_) {
      if (mounted) {
        context.read<DosenRequestController>().loadMyRequests(widget.dosen.id);
      }
    });
  }
}

// ── Request Card ──────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final ScheduleRequestModel request;
  final VoidCallback? onCancel;
  final bool willBeDeleted;

  const _RequestCard({
    required this.request,
    this.onCancel,
    this.willBeDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: willBeDeleted ? 0.65 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: willBeDeleted
                ? Colors.red.shade300
                : request.isLate == true
                ? Colors.red.shade100
                : AppColors.slate200,
            width: willBeDeleted ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner akan dihapus
            if (willBeDeleted)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: Colors.red.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Akan dibatalkan setelah online',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Header ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (request.namaMk != null && request.namaMk!.isNotEmpty)
                            ? request.namaMk!
                            : 'Permohonan: ${request.alasan}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.kelas ?? '-',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.slate400,
                        ),
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
                        '${request.hariJadwal ?? request.detailPerubahan.hariBaru ?? '-'}\n'
                        '${request.jamMulaiJadwal ?? request.detailPerubahan.jamMulaiBaru ?? '-'}–'
                        '${request.jamSelesaiJadwal ?? request.detailPerubahan.jamSelesaiBaru ?? '-'}\n'
                        '${request.ruanganJadwal ?? request.detailPerubahan.ruanganBaru ?? '-'}',
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

            // ── Catatan admin ─────────────────────────────
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

            // ── Tombol batal ──────────────────────────────
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
                  Icon(
                    Icons.warning_amber,
                    size: 13,
                    color: Colors.red.shade400,
                  ),
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
      ),
    );
  }
}

// ── Sub Widgets ───────────────────────────────────────────

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
  const _EmptyState();

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
