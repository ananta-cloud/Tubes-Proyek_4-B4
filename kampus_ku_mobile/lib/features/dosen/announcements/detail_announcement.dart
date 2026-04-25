import 'package:flutter/material.dart';

class DetailAnnouncementDosen extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const DetailAnnouncementDosen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF3F5DB3);
    final accentOrange = const Color(0xFFFF7A36);
    final darkText = const Color(0xFF1F1F3D);
    final isImportant = announcement['important'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FA),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text("Detail Pengumuman", style: TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                blurRadius: 15,
                offset: const Offset(0, 5),
                color: Colors.black.withOpacity(0.05),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge & Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isImportant ? accentOrange.withOpacity(0.1) : primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isImportant ? Icons.error_outline : Icons.info_outline,
                          size: 14,
                          color: isImportant ? accentOrange : primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isImportant ? "PENTING" : "INFORMASI",
                          style: TextStyle(
                            color: isImportant ? accentOrange : primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    announcement['date'] ?? "Hari ini",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                announcement['title'] ?? "Tanpa Judul",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText),
              ),
              
              const SizedBox(height: 12),
              
              // Kategori Tag
              if (announcement['category'] != null)
                Text(
                  "Kategori: ${announcement['category']}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                ),
                
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFEAF3FA), thickness: 2),
              const SizedBox(height: 20),
              
              // Full Description
              Text(
                announcement['desc'] ?? "Tidak ada deskripsi",
                style: TextStyle(
                  fontSize: 15, 
                  color: darkText.withOpacity(0.85), 
                  height: 1.6, // Membuat jarak antar baris lebih nyaman dibaca
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Aksi Bookmark (Hanya Tampilan/Dummy sementara)
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Tersimpan ke Bookmark!")),
                    );
                  },
                  icon: const Icon(Icons.bookmark_border, size: 18),
                  label: const Text("Simpan"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: BorderSide(color: primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}