import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import 'package:kampus_ku_mobile/controller/schedule_controller.dart';
// import '../../../../data/models/schedule_local_model.dart';
import 'create_page.dart';
// import 'edit_page.dart';
import '../widgets/mini_stat.dart';
import '../widgets/filter_chip.dart';
import '../widgets/schedule_card.dart';
import '../widgets/empty_state.dart';

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
    final role = 'TIM_PENJADWALAN';

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
          // ── Stats
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                MiniStat(
                  label: 'Draft',
                  value: ctrl.countDraft,
                  color: AppColors.slate400,
                ),
                const SizedBox(width: 10),
                MiniStat(
                  label: 'Published',
                  value: ctrl.countPublished,
                  color: AppColors.emerald700,
                ),
              ],
            ),
          ),

          // ── Search
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.slate200),
                ),
              ),
            ),
          ),

          // ── Filter
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChipWidget(
                  label: 'Semua',
                  selected: ctrl.filterStatus == null,
                  onTap: () {
                    ctrl.setFilter();
                    ctrl.loadSchedules(widget.idJurusan);
                  },
                ),
                FilterChipWidget(
                  label: 'Draft',
                  selected: ctrl.filterStatus == 'DRAFT',
                  onTap: () {
                    ctrl.setFilter(status: 'DRAFT');
                    ctrl.loadSchedules(widget.idJurusan);
                  },
                ),
                FilterChipWidget(
                  label: 'Final',
                  selected: ctrl.filterStatus == 'FINAL',
                  onTap: () {
                    ctrl.setFilter(status: 'FINAL');
                    ctrl.loadSchedules(widget.idJurusan);
                  },
                ),
                FilterChipWidget(
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

          // ── List
          Expanded(
            child: ctrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ctrl.schedules.isEmpty
                ? EmptyState(
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
                      padding: const EdgeInsets.all(12),
                      itemCount: ctrl.schedules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => ScheduleCard(
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
