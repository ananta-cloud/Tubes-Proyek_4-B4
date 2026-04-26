import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kampus_ku_mobile/features/announcements/data/models/announcement_local_model.dart';

class DetailAnnouncementPage extends StatefulWidget {
  final AnnouncementLocalModel announcement;

  const DetailAnnouncementPage({super.key, required this.announcement});

  @override
  State<DetailAnnouncementPage> createState() => _DetailAnnouncementPageState();
}

class _DetailAnnouncementPageState extends State<DetailAnnouncementPage> {
  final Color primaryBlue = const Color(0xFF3F5DB3);
  final Color accentOrange = const Color(0xFFFF7A36);
  final Color darkText = const Color(0xFF1F1F3D);

  late Box<AnnouncementLocalModel> bookmarkBox;
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    // Membuka box bookmarks
    bookmarkBox = Hive.box<AnnouncementLocalModel>('bookmarks');
    _checkBookmarkStatus();
  }

  void _checkBookmarkStatus() {
    setState(() {
      isBookmarked = bookmarkBox.containsKey(widget.announcement.id);
    });
  }

  void _toggleBookmark() async {
    if (isBookmarked) {
      await bookmarkBox.delete(widget.announcement.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dihapus dari Tersimpan")));
    } else {
      await bookmarkBox.put(widget.announcement.id, widget.announcement);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil Disimpan!")));
    }
    _checkBookmarkStatus();
  }

  @override
  Widget build(BuildContext context) {
    final ann = widget.announcement;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FA),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text("Detail Pengumuman", style: TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
            onPressed: _toggleBookmark,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(blurRadius: 15, offset: const Offset(0, 5), color: Colors.black.withOpacity(0.05))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ann.isImportant ? accentOrange.withOpacity(0.1) : primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ann.isImportant ? Icons.error_outline : Icons.info_outline, size: 14, color: ann.isImportant ? accentOrange : primaryBlue),
                        const SizedBox(width: 6),
                        Text(
                          ann.isImportant ? "PENTING" : "INFORMASI",
                          style: TextStyle(color: ann.isImportant ? accentOrange : primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Text(ann.tanggal, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),
              Text(ann.judul, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
              const SizedBox(height: 12),
              Text("Target: ${ann.kategori}", style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFEAF3FA), thickness: 2),
              const SizedBox(height: 20),
              Text(
                ann.isi,
                style: TextStyle(fontSize: 15, color: darkText.withOpacity(0.85), height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}