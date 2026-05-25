import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/theme/app_colors.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/features/dosen/requests/viewmodels/dosen_request_controller.dart';
import 'package:sigma/features/dosen/schedules/widgets/jadwal_card.dart';
import 'package:sigma/data/models/dosen_model.dart';

class JadwalMengajarPage extends StatefulWidget {
  final UserModel user;
  final DosenModel dosen;
  const JadwalMengajarPage({
    super.key,
    required this.user,
    required this.dosen,
  });

  @override
  State<JadwalMengajarPage> createState() => _JadwalMengajarPageState();
}

class _JadwalMengajarPageState extends State<JadwalMengajarPage> {
  String _filterHari = 'SEMUA';

  static const _hariList = [
    'SEMUA',
    'SENIN',
    'SELASA',
    'RABU',
    'KAMIS',
    'JUMAT',
    'SABTU',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DosenRequestController>().loadMySchedules(
          widget.dosen.kodeDosen,
        );
      }
    });
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> jadwals) {
    if (_filterHari == 'SEMUA') return jadwals;
    return jadwals.where((j) => j['hari']?.toString() == _filterHari).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DosenRequestController>();
    final filtered = _filtered(ctrl.mySchedules);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Jadwal Mengajar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1F3D),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (ctrl.isOffline)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: 'Mode Offline',
                child: Icon(
                  Icons.cloud_off,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Banner offline
          if (ctrl.isOffline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: const Text(
                'Mode Offline — menampilkan data tersimpan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Filter hari
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _hariList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final hari = _hariList[i];
                final isSelected = _filterHari == hari;
                return GestureDetector(
                  onTap: () => setState(() => _filterHari = hari),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF3F5DB3)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3F5DB3)
                            : AppColors.slate200,
                      ),
                    ),
                    child: Text(
                      hari == 'SEMUA' ? 'Semua' : _shortHari(hari),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.slate500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          Expanded(
            child: ctrl.isLoadingSchedules
                ? const Center(child: CircularProgressIndicator())
                : ctrl.mySchedules.isEmpty
                ? _EmptyState(isOffline: ctrl.isOffline)
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: AppColors.slate300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada jadwal hari $_filterHari',
                          style: TextStyle(color: AppColors.slate500),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => context
                        .read<DosenRequestController>()
                        .loadMySchedules(widget.dosen.kodeDosen),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          JadwalCard(jadwal: filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _shortHari(String hari) {
    const map = {
      'SENIN': 'Sen',
      'SELASA': 'Sel',
      'RABU': 'Rab',
      'KAMIS': 'Kam',
      'JUMAT': 'Jum',
      'SABTU': 'Sab',
    };
    return map[hari] ?? hari;
  }
}

class _EmptyState extends StatelessWidget {
  final bool isOffline;
  const _EmptyState({required this.isOffline});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isOffline ? Icons.cloud_off : Icons.event_busy,
          size: 52,
          color: AppColors.slate300,
        ),
        const SizedBox(height: 12),
        Text(
          isOffline ? 'Tidak ada data tersimpan' : 'Belum ada jadwal mengajar',
          style: TextStyle(
            color: AppColors.slate500,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isOffline
              ? 'Buka halaman ini saat online untuk menyimpan data'
              : 'Jadwal yang diampu akan muncul di sini',
          style: TextStyle(color: AppColors.slate400, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
