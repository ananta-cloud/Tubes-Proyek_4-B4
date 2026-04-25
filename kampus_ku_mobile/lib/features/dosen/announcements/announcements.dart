import 'package:flutter/material.dart';
import 'detail_announcement.dart';

class AnnouncementsDosen extends StatefulWidget {
  const AnnouncementsDosen({super.key});

  @override
  State<AnnouncementsDosen> createState() => _AnnouncementsDosenState();
}

class _AnnouncementsDosenState extends State<AnnouncementsDosen> {
  final Color primaryBlue = const Color(0xFF3F5DB3);
  final Color accentOrange = const Color(0xFFFF7A36);
  final Color darkText = const Color(0xFF1F1F3D);

  String searchQuery = "";

  // Data Dummy Pengumuman (Bisa diganti dengan data dari API/MongoDB nanti)
  final List<Map<String, dynamic>> allAnnouncements = [
    {
      "title": "Rapat Evaluasi Kurikulum",
      "desc": "Diwajibkan bagi seluruh dosen TKI untuk menghadiri rapat evaluasi kurikulum semester genap yang akan diadakan di Ruang Rapat Jurusan. Harap membawa dokumen RKPS masing-masing.",
      "important": true,
      "date": "20 Mei 2026",
      "category": "Jurusan"
    },
    {
      "title": "Batas Input Nilai UTS",
      "desc": "Batas akhir penginputan nilai UTS ke dalam sistem akademik adalah 25 Mei 2026. Mohon segera diselesaikan agar mahasiswa dapat melihat hasilnya tepat waktu.",
      "important": false,
      "date": "18 Mei 2026",
      "category": "Akademik"
    },
    {
      "title": "Maintenance Server SIGMA",
      "desc": "Akses sistem SIGMA akan dihentikan sementara pada pukul 23:00 - 02:00 WIB untuk keperluan pemeliharaan server pusat.",
      "important": false,
      "date": "17 Mei 2026",
      "category": "Umum"
    },
    {
      "title": "Pengambilan SK Mengajar",
      "desc": "SK Mengajar semester baru sudah bisa diambil di Tata Usaha Jurusan pada jam kerja (08.00 - 15.00 WIB).",
      "important": false,
      "date": "15 Mei 2026",
      "category": "Khusus Dosen"
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Logika Filter Pencarian
    final filteredAnnouncements = allAnnouncements.where((ann) {
      final titleLower = ann['title'].toLowerCase();
      final descLower = ann['desc'].toLowerCase();
      final searchLower = searchQuery.toLowerCase();
      return titleLower.contains(searchLower) || descLower.contains(searchLower);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            "Pengumuman Kampus",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText),
          ),
        ),
        const SizedBox(height: 15),

        // --- WIDGET PENCARIAN ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(blurRadius: 10, offset: const Offset(0, 4), color: Colors.black.withOpacity(0.05))
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Cari judul atau isi...",
                border: InputBorder.none,
                icon: Icon(Icons.search, color: primaryBlue),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // --- FILTER KATEGORI ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _chip("Semua", true),
              _chip("Khusus Dosen", false),
              _chip("Jurusan", false),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // --- LIST VIEW PENGUMUMAN ---
        Expanded(
          child: filteredAnnouncements.isEmpty
              ? const Center(
                  child: Text("Pengumuman tidak ditemukan.", style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 100), // Padding bawah agar tidak tertutup navbar
                  itemCount: filteredAnnouncements.length,
                  itemBuilder: (context, index) {
                    final ann = filteredAnnouncements[index];
                    return _announcementItem(context, ann);
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(String text, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? primaryBlue : Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: active ? Colors.white : darkText, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _announcementItem(BuildContext context, Map<String, dynamic> ann) {
    final bool important = ann['important'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(blurRadius: 8, offset: const Offset(0, 2), color: Colors.black.withOpacity(0.04))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // NAVIGASI KE HALAMAN DETAIL
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailAnnouncementDosen(announcement: ann),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: important ? accentOrange : Colors.grey.shade300, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ann['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      important ? Icons.error_outline : Icons.info_outline,
                      color: important ? accentOrange : Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ann['desc'],
                  style: TextStyle(color: darkText.withOpacity(0.6), fontSize: 13),
                  maxLines: 2, // Membatasi text yang panjang di list
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ann['date'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      "Baca selengkapnya",
                      style: TextStyle(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}