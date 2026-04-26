import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

/// Placeholder — akan diisi setelah ScheduleRequestsService dibuat.
/// Struktur screen mengikuti requests/index.blade.php
class RequestsIndexPage extends StatefulWidget {
  final String idJurusan;
  const RequestsIndexPage({super.key, required this.idJurusan});

  @override
  State<RequestsIndexPage> createState() => _RequestsIndexPageState();
}

class _RequestsIndexPageState extends State<RequestsIndexPage> {
  String _filterStatus = 'SEMUA';
  bool _isLoading = false;

  // TODO: ganti dengan data dari ScheduleRequestsService
  final List<Map<String, dynamic>> _requests = [];

  final List<String> _filters = ['SEMUA', 'PENDING', 'APPROVED', 'REJECTED'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Request Perubahan Jadwal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.indigo900,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Stats Cards ───────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _StatChip(
                  label: 'Pending',
                  value: 0,
                  color: const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Approved',
                  value: 0,
                  color: AppColors.emerald700,
                ),
                const SizedBox(width: 8),
                _StatChip(label: 'Ditolak', value: 0, color: Colors.red),
              ],
            ),
          ),

          // ── Filter Tabs ───────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 12, bottom: 12),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _filters.map((f) {
                  final selected = _filterStatus == f;
                  Color activeColor = AppColors.indigo700;
                  if (f == 'PENDING') activeColor = const Color(0xFFD97706);
                  if (f == 'APPROVED') activeColor = AppColors.emerald700;
                  if (f == 'REJECTED') activeColor = Colors.red;

                  return GestureDetector(
                    onTap: () => setState(() => _filterStatus = f),
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

          const SizedBox(height: 1),

          // ── List ─────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 48, color: AppColors.slate300),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada request${_filterStatus != 'SEMUA' ? ' dengan status $_filterStatus' : ''}',
                          style: TextStyle(color: AppColors.slate500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _RequestCard(
                      request: _requests[i],
                      onApprove: () {
                        /* TODO */
                      },
                      onReject: () {
                        /* TODO */
                      },
                      onDetail: () {
                        /* TODO: push RequestDetailPage */
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDetail;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? 'PENDING';
    final tipe = request['tipe_request'] ?? '-';
    final isPending = status == 'PENDING';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
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
                      request['nama_mk'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person, size: 12, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(
                          request['nama_dosen'] ?? '-',
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
              _StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: 8),
          Divider(color: AppColors.slate100, height: 1),
          const SizedBox(height: 8),

          // Tipe request badge
          _TipeBadge(tipe: tipe),
          const SizedBox(height: 6),

          // Alasan
          if (request['alasan'] != null)
            Text(
              request['alasan'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.slate600),
            ),

          // Tanggal
          const SizedBox(height: 6),
          Text(
            request['created_at'] ?? '',
            style: TextStyle(fontSize: 10, color: AppColors.slate400),
          ),

          const SizedBox(height: 10),

          // ── Aksi ─────────────────────────────────────────
          if (isPending)
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

// ── Sub widgets ───────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      border: Border(left: BorderSide(color: color, width: 3)),
      color: AppColors.slate50,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.slate500)),
      ],
    ),
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
      case 'GANTI_RUANGAN':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        icon = Icons.door_front_door;
        break;
      case 'GANTI_WAKTU':
        bg = const Color(0xFFF5F3FF);
        text = const Color(0xFF6D28D9);
        icon = Icons.access_time;
        break;
      case 'GANTI_DOSEN':
        bg = const Color(0xFFFFF7ED);
        text = const Color(0xFFC2410C);
        icon = Icons.person_outline;
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

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
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
