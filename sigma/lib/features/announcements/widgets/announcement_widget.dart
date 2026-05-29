import 'package:flutter/material.dart';
import 'package:sigma/data/models/announcement_model.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback? onTap;
  final bool isLecturer;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
    this.isLecturer = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Colors.blue.shade700;
    final Color accentOrange = Colors.orange.shade600;
    const Color darkText = Colors.black87;

    // Logika warna garis berdasarkan tingkat kepentingan
    Color indikatorWarna;
    switch (announcement.tingkatKepentingan.toUpperCase()) {
      case 'SANGAT PENTING':
        indikatorWarna = Colors.red;
        break;
      case 'PENTING':
        indikatorWarna = accentOrange;
        break;
      case 'BIASA':
        indikatorWarna = Colors.grey.shade500;
        break;
      default:
        indikatorWarna = primaryBlue.withOpacity(0.5);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Garis Indikator di Kiri
                Container(width: 6, color: indikatorWarna),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Label Target Audience
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                announcement.targetAudience.replaceAll(
                                  '_',
                                  ' ',
                                ),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                            // Label Tingkat Kepentingan
                            Text(
                              announcement.tingkatKepentingan.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: indikatorWarna,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Judul
                        Text(
                          announcement.judul,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkText,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        if (announcement.attachments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.attach_file_rounded, size: 16, color: Colors.blueGrey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  "${announcement.attachments.length} Lampiran",
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.w600, 
                                    color: Colors.blueGrey.shade600
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 5),
                        // Kategori (Hashtags)
                        if (announcement.kategori.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children: announcement.kategori.map((kat) {
                              return Text(
                                "#$kat",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: accentOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 10),
                        // Bagian Bawah: Publisher & Icon Edit
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              announcement.namaPublisher,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            // Ikon Edit Khusus Dosen
                            if (isLecturer)
                              const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
