import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/features/penjadwalan/viewmodels/schedule_request_controller.dart';
import 'package:sigma/data/models/schedule_request_model.dart';
import 'request_detail_page.dart';
import 'package:sigma/features/dosen/requests/views/widgets/offline_banner.dart';

import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/shared/app_colors.dart';

import '../../widgets/status_badge.dart';
import '../../widgets/tipe_badge.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/empty_state.dart';

class RequestsIndexPage extends StatefulWidget {
  final String idJurusan;
  final UserModel user;

  const RequestsIndexPage({
    super.key,
    required this.idJurusan,
    required this.user,
  });

  @override
  State<RequestsIndexPage> createState() => _RequestsIndexPageState();
}

class _RequestsIndexPageState extends State<RequestsIndexPage> {
  final List<String> _filters = ['SEMUA', 'PENDING', 'APPROVED', 'REJECTED'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleRequestController>().loadRequests(widget.idJurusan);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScheduleRequestController>();

    if (ctrl.justSynced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Flexible(child: Text('Request berhasil tersinkronisasi')),
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

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Perubahan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Tim Penjadwalan · ${widget.user.nama}',
              style: TextStyle(fontSize: 11, color: Colors.indigo.shade200),
            ),
          ],
        ),
        backgroundColor: AppColors.indigo900,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Stats Cards ──────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Pending',
                    value: ctrl.countPending,
                    accent: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Disetujui',
                    value: ctrl.countApproved,
                    accent: AppColors.emerald700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Ditolak',
                    value: ctrl.countRejected,
                    accent: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // ── Filter Tabs ──────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 12, bottom: 12, top: 4),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _filters.map((f) {
                  final selected = ctrl.filterStatus == f;
                  Color activeColor = AppColors.indigo700;
                  if (f == 'PENDING') activeColor = const Color(0xFFD97706);
                  if (f == 'APPROVED') activeColor = AppColors.emerald700;
                  if (f == 'REJECTED') activeColor = Colors.red;

                  return GestureDetector(
                    onTap: () => ctrl.setFilter(f, widget.idJurusan),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? activeColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? activeColor : AppColors.slate300,
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.slate600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ── List ─────────────────────────────────────
          Expanded(
            child: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ctrl.requests.isEmpty
                ? EmptyState(filter: ctrl.filterStatus)
                : RefreshIndicator(
                    onRefresh: () => ctrl.loadRequests(widget.idJurusan),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                      itemCount:
                          ctrl.requests.length + (ctrl.isOffline ? 1 : 0),
                      separatorBuilder: (_, i) => i == 0 && ctrl.isOffline
                          ? const SizedBox.shrink()
                          : const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        if (ctrl.isOffline && i == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: OfflineBanner(),
                          );
                        }
                        final req = ctrl.requests[ctrl.isOffline ? i - 1 : i];
                        return _RequestCard(
                          request: req,
                          onDetail: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: ctrl,
                                child: RequestDetailPage(
                                  request: req,
                                  user: widget.user,
                                  idJurusan: widget.idJurusan,
                                ),
                              ),
                            ),
                          ),
                          onApprove: () => _showApproveDialog(ctrl, req),
                          onReject: () => _showRejectDialog(ctrl, req),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Approve Dialog ──────────────────────────────────────
  void _showApproveDialog(
    ScheduleRequestController ctrl,
    ScheduleRequestModel req,
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
              'Perubahan akan langsung diterapkan ke jadwal ${req.namaMk ?? ''}.',
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
                requestId: req.id,
                processorId: widget.user.id,
                idJurusan: widget.idJurusan,
                request: req,
                catatan: catatanCtrl.text.trim().isEmpty
                    ? null
                    : catatanCtrl.text.trim(),
              );
              if (mounted) {
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
              }
            },
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Reject Dialog ───────────────────────────────────────
  void _showRejectDialog(
    ScheduleRequestController ctrl,
    ScheduleRequestModel req,
  ) {
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
                requestId: req.id,
                processorId: widget.user.id,
                idJurusan: widget.idJurusan,
                catatan: catatanCtrl.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Request ditolak' : 'Gagal menolak request',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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

class _RequestCard extends StatelessWidget {
  final ScheduleRequestModel request;
  final VoidCallback onDetail, onApprove, onReject;

  const _RequestCard({
    required this.request,
    required this.onDetail,
    required this.onApprove,
    required this.onReject,
  });

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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.person, size: 12, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(
                          request.namaDosen,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.slate100, height: 1),
          const SizedBox(height: 8),
          TipeBadge(tipe: request.tipeRequest),
          const SizedBox(height: 6),
          Text(
            request.alasan,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.slate600),
          ),
          const SizedBox(height: 10),

          // ── Aksi ──────────────────────────────────────────
          if (request.isPending)
            Row(
              children: [
                _ActionBtn(
                  label: 'Detail',
                  icon: Icons.visibility,
                  color: AppColors.indigo700,
                  bg: const Color(0xFFEEF2FF),
                  onTap: onDetail,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  label: 'Approve',
                  icon: Icons.check,
                  color: AppColors.emerald700,
                  bg: AppColors.emerald100,
                  onTap: onApprove,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  label: 'Reject',
                  icon: Icons.close,
                  color: Colors.red,
                  bg: const Color(0xFFFEE2E2),
                  onTap: onReject,
                ),
              ],
            )
          else
            _ActionBtn(
              label: 'Detail',
              icon: Icons.visibility,
              color: AppColors.indigo700,
              bg: const Color(0xFFEEF2FF),
              onTap: onDetail,
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}
