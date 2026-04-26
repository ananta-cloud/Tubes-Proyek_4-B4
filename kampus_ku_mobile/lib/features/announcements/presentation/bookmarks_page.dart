import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kampus_ku_mobile/features/announcements/data/models/announcement_local_model.dart';
import 'detail_announcement_page.dart';

class BookmarksAnnouncementPage extends StatelessWidget {
  const BookmarksAnnouncementPage({super.key});

  final Color primaryBlue = const Color(0xFF3F5DB3);
  final Color darkText = const Color(0xFF1F1F3D);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text("Pengumuman Tersimpan", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: Hive.box<AnnouncementLocalModel>('bookmarks').listenable(),
            builder: (context, Box<AnnouncementLocalModel> box, _) {
              final bookmarks = box.values.toList();

              if (bookmarks.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("Belum ada pengumuman yang disimpan.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final ann = bookmarks[index];
                  return _bookmarkItem(context, ann, box);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bookmarkItem(BuildContext context, AnnouncementLocalModel ann, Box box) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailAnnouncementPage(announcement: ann)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(ann.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: Icon(Icons.bookmark, color: primaryBlue, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        box.delete(ann.id); // Hapus langsung dari bookmark
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dihapus dari Tersimpan")));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(ann.isi, style: TextStyle(color: darkText.withOpacity(0.6), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}