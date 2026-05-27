import 'package:flutter/material.dart';
import 'package:sigma/theme/app_colors.dart';

class JadwalCard extends StatelessWidget {
  final Map<String, dynamic> jadwal;
  const JadwalCard({super.key, required this.jadwal});

  Color get _tipeColor {
    switch (jadwal['tipe']?.toString()) {
      case 'UTS':
        return Colors.orange;
      case 'UAS':
        return Colors.red;
      default:
        return const Color(0xFF3F5DB3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hari = jadwal['hari']?.toString() ?? '-';
    final jamMulai = jadwal['jam_mulai']?.toString() ?? '-';
    final jamSelesai = jadwal['jam_selesai']?.toString() ?? '-';
    final ruangan = jadwal['ruangan']?.toString() ?? '-';
    // final namaMk = jadwal['nama_mk']?.toString() ?? '-';
    final namaMk =
        (jadwal['nama_matkul'] != null &&
            jadwal['nama_matkul'].toString().isNotEmpty)
        ? jadwal['nama_matkul'].toString()
        : (jadwal['namaMk'] != null && jadwal['namaMk'].toString().isNotEmpty)
        ? jadwal['namaMk'].toString()
        : (jadwal['nama_matkul'] != null &&
              jadwal['nama_matkul'].toString().isNotEmpty)
        ? jadwal['nama_matkul'].toString()
        : (jadwal['namaMatkul'] != null &&
              jadwal['tahun_akademik'].toString().isNotEmpty)
        ? jadwal['namaMatkul'].toString()
        : 'Mata Kuliah Tidak Terdefinisi';
    final kelas = jadwal['kelas']?.toString() ?? '-';
    final tipe = jadwal['tipe']?.toString() ?? 'KULIAH';
    final semester = jadwal['semester']?.toString() ?? '-';
    final tahunAkademik = jadwal['tahun_akademik']?.toString() ?? '-';
    final jamKe =
        jadwal['jam_ke']?.toString() ?? jadwal['jamKe']?.toString() ?? '';
    final tePr =
        jadwal['te_pr']?.toString() ?? jadwal['tePr']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _tipeColor.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _tipeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tipe,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$semester · $tahunAkademik',
                  style: TextStyle(fontSize: 11, color: AppColors.slate400),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaMk,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kelas,
                  style: TextStyle(fontSize: 12, color: AppColors.slate400),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: hari,
                      color: _tipeColor,
                    ),
                    if (jamKe.isNotEmpty)
                      _InfoChip(
                        icon: Icons.format_list_numbered,
                        label: 'Jam ke-$jamKe',
                        color: _tipeColor,
                      ),
                    _InfoChip(
                      icon: Icons.access_time,
                      label: '$jamMulai–$jamSelesai',
                      color: _tipeColor,
                    ),
                    _InfoChip(
                      icon: Icons.room,
                      label: ruangan,
                      color: _tipeColor,
                    ),
                    if (tePr.isNotEmpty)
                      _InfoChip(
                        icon: Icons.science_outlined,
                        label: tePr,
                        color: tePr == 'PR' ? Colors.teal : _tipeColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(8),
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
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
