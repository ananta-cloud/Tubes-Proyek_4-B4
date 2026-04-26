import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';
import '../../../../data/models/schedule_local_model.dart';
import 'create_page.dart';
import 'edit_page.dart';

class ScheduleIndexPage extends StatefulWidget {
  final String idJurusan;
  const ScheduleIndexPage({super.key, required this.idJurusan});

  @override
  State<ScheduleIndexPage> createState() => _ScheduleIndexPageState();
}

class _ScheduleIndexPageState extends State<ScheduleIndexPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleController>().loadSchedules(widget.idJurusan);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScheduleController>();
    final role = 'TIM_PENJADWALAN'; // TODO: ambil dari auth state

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Daftar Jadwal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.indigo900,
        foregroundColor: Colors.white,
        actions: [
          if (role == 'TIM_PENJADWALAN')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ScheduleCreatePage(idJurusan: widget.idJurusan),
                ),
              ).then((_) => ctrl.loadSchedules(widget.idJurusan)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats ────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _MiniStat(
                  label: 'Draft',
                  value: ctrl.countDraft,
                  color: AppColors.slate400,
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  label: 'Published',
                  value: ctrl.countPublished,
                  color: AppColors.emerald700,
                ),
              ],
            ),
          ),

          // ── Search ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                ctrl.setSearch(v);
                ctrl.loadSchedules(widget.idJurusan);
              },
              decoration: InputDecoration(
                hintText: 'Cari matkul, dosen, ruangan...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          ),

          // ── Filter Chips ─────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: ctrl.filterStatus == null,
                  onTap: () {
                    ctrl.setFilter();
                    ctrl.loadSchedules(widget.idJurusan);
                  },
                ),
                _FilterChip(
                  label: 'Draft',
                  selected: ctrl.filterStatus == 'DRAFT',
                  onTap: () {
                    ctrl.setFilter(status: 'DRAFT');
                    ctrl.loadSchedules(widget.idJurusan);
                  },
                ),
                _FilterChip(
                  label: 'Final',
                  selected: ctrl.filterStatus == 'FINAL',
                  onTap: () {
                    ctrl.setFilter(status: 'FINAL');
                    ctrl.loadSchedules(widget.idJurusan);
                  },
                ),
                _FilterChip(
                  label: 'Published',
                  selected: ctrl.filterStatus == 'PUBLISHED',
                  onTap: () {
                    ctrl.setFilter(status: 'PUBLISHED');
                    ctrl.loadSchedules(widget.idJurusan);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── List ─────────────────────────────────────────
          Expanded(
            child: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ctrl.schedules.isEmpty
                ? _EmptyState(
                    onAdd: role == 'TIM_PENJADWALAN'
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScheduleCreatePage(
                                idJurusan: widget.idJurusan,
                              ),
                            ),
                          )
                        : null,
                  )
                : RefreshIndicator(
                    onRefresh: () => ctrl.loadSchedules(widget.idJurusan),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      itemCount: ctrl.schedules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ScheduleCard(
                        jadwal: ctrl.schedules[i],
                        role: role,
                        idJurusan: widget.idJurusan,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Schedule Card ─────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final ScheduleLocalModel jadwal;
  final String role;
  final String idJurusan;

  const _ScheduleCard({
    required this.jadwal,
    required this.role,
    required this.idJurusan,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<ScheduleController>();

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
                      jadwal.namaMk,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      jadwal.dosen,
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: jadwal.status),
            ],
          ),

          const SizedBox(height: 8),
          Divider(color: AppColors.slate100, height: 1),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.access_time, size: 13, color: AppColors.slate400),
              const SizedBox(width: 4),
              Text(
                '${jadwal.hari}, ${jadwal.jamMulai}–${jadwal.jamSelesai}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.room, size: 13, color: AppColors.slate400),
              const SizedBox(width: 4),
              Text(
                jadwal.ruangan,
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Aksi per role ─────────────────────────────
          _buildActions(context, ctrl),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ScheduleController ctrl) {
    if (role == 'TIM_PENJADWALAN') {
      if (jadwal.status == 'DRAFT') {
        return Row(
          children: [
            _ActionBtn(
              label: 'Edit',
              icon: Icons.edit,
              color: AppColors.indigo700,
              bg: const Color(0xFFEEF2FF),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ScheduleEditPage(jadwal: jadwal, idJurusan: idJurusan),
                ),
              ).then((_) => ctrl.loadSchedules(idJurusan)),
            ),
          ],
        );
      } else if (jadwal.status == 'FINAL') {
        return Text(
          'Menunggu Admin TU',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.yellow700,
            fontStyle: FontStyle.italic,
          ),
        );
      }
      return Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: AppColors.emerald700),
          const SizedBox(width: 4),
          Text(
            'Live di HP Mahasiswa',
            style: TextStyle(fontSize: 11, color: AppColors.emerald700),
          ),
        ],
      );
    }

    if (role == 'ADMIN_TU') {
      if (jadwal.status == 'DRAFT') {
        return _ActionBtn(
          label: 'Finalisasi',
          icon: Icons.check,
          color: AppColors.indigo700,
          bg: const Color(0xFFEEF2FF),
          onTap: () async {
            final ok = await ctrl.finalizeSchedule(jadwal.id, idJurusan);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Jadwal berhasil difinalisasi' : 'Gagal finalisasi',
                  ),
                ),
              );
            }
          },
        );
      } else if (jadwal.status == 'FINAL') {
        return _ActionBtn(
          label: 'Publikasi',
          icon: Icons.send,
          color: AppColors.emerald700,
          bg: AppColors.emerald100,
          onTap: () => _showPublishDialog(context, ctrl),
        );
      }
      return Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: AppColors.emerald700),
          const SizedBox(width: 4),
          Text(
            'Live di HP Mahasiswa',
            style: TextStyle(fontSize: 11, color: AppColors.emerald700),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showPublishDialog(BuildContext context, ScheduleController ctrl) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.send, color: AppColors.emerald700),
            const SizedBox(width: 8),
            const Text(
              'Publikasi Jadwal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Jadwal akan dikirim ke mahasiswa via Push Notification.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Pesan pengantar (wajib)...',
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
            onPressed: () {
              if (msgCtrl.text.trim().length < 5) return;
              Navigator.pop(context);
              // TODO: panggil publish service
            },
            child: const Text(
              'Kirim & Publikasi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub widgets ───────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo700 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.indigo700 : AppColors.slate300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.slate600,
          ),
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text, border;
    switch (status) {
      case 'FINAL':
        bg = AppColors.yellow100;
        text = AppColors.yellow700;
        border = AppColors.yellow200;
        break;
      case 'PUBLISHED':
        bg = AppColors.emerald100;
        text = AppColors.emerald700;
        border = AppColors.emerald200;
        break;
      default:
        bg = AppColors.slate100;
        text = AppColors.slate600;
        border = AppColors.slate200;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
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
  final VoidCallback? onAdd;
  const _EmptyState({this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 48, color: AppColors.slate300),
          const SizedBox(height: 12),
          Text(
            'Belum ada jadwal',
            style: TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Input Jadwal Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
