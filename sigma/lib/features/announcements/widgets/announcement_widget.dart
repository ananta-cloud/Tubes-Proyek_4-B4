import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:sigma/data/models/announcement_model.dart';
=======
import 'package:sigma/features/admin_tu/announcements/models/announcement_model.dart';
>>>>>>> nazriel

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback? onTap;
  final bool isLecturer;

  const AnnouncementCard({
<<<<<<< HEAD
    super.key, 
    required this.announcement, 
=======
    super.key,
    required this.announcement,
>>>>>>> nazriel
    this.onTap,
    this.isLecturer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          announcement.judul,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
<<<<<<< HEAD
            Text(announcement.isi, maxLines: 2, overflow: TextOverflow.ellipsis),
=======
            Text(
              announcement.isi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
>>>>>>> nazriel
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
<<<<<<< HEAD
                Text(announcement.namaPublisher, style: const TextStyle(fontSize: 12)),
=======
                Text(
                  announcement.namaPublisher,
                  style: const TextStyle(fontSize: 12),
                ),
>>>>>>> nazriel
                const Spacer(),
                if (isLecturer)
                  const Icon(Icons.edit, size: 16, color: Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> nazriel
