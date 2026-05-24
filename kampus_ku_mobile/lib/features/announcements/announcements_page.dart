import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kampus_ku_mobile/controller/announcement_controller.dart';
import 'package:kampus_ku_mobile/data/models/announcement_model.dart';
import 'announcement_detail_page.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  final Color primaryBlue = const Color(0xFF3F5DB3);
  final Color accentOrange = const Color(0xFFFF7A36);
  final Color darkText = const Color(0xFF1F1F3D);

  String searchQuery = "";
  String activeFilter = "Semua";

  @override
  void initState() {
    super.initState();
    // Panggil sync dari API saat halaman dibuka pertama kali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementController>().syncAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column( 
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text("Pengumuman Kampus", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText)),
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
              boxShadow: [BoxShadow(blurRadius: 10, offset: const Offset(0, 4), color: Colors.black.withOpacity(0.05))],
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

        // --- FILTER TARGET ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _filterChip("Semua"),
              _filterChip("Dosen"),
              _filterChip("Jurusan"),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // --- LIST VIEW MENGGUNAKAN CONTROLLER ---
        Expanded(
          child: Consumer<AnnouncementController>(
            builder: (context, controller, child) {
              // Tampilkan Loading
              if (controller.isLoading && controller.announcements.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // 🔥 LOGIKA FILTER YANG SUDAH DIPERBAIKI
              final filtered = controller.announcements.where((ann) {
                // 1. Pencarian Teks
                final matchesSearch = ann.judul.toLowerCase().contains(searchQuery.toLowerCase()) || 
                                      ann.isi.toLowerCase().contains(searchQuery.toLowerCase());
                
                // 2. Filter Kategori / Target Audience
                bool matchTarget = true;
                String targetAudience = ann.targetAudience.toLowerCase();
                String kategori = ann.kategori.join(' ').toLowerCase();

                if (activeFilter == "Dosen") {
                  // Cek apakah target audience ATAU kategorinya mengandung kata "dosen"
                  matchTarget = targetAudience.contains("dosen") || kategori.contains("dosen");
                } else if (activeFilter == "Jurusan") {
                  // Cek apakah target audience adalah prodi/jurusan
                  matchTarget = targetAudience.contains("prodi") || targetAudience.contains("jurusan") || kategori.contains("jurusan");
                }
                // Jika "Semua", matchTarget biarkan tetap true

                return matchesSearch && matchTarget;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(controller.isLoading ? "Memuat..." : "Tidak ada pengumuman.", style: const TextStyle(color: Colors.grey)),
                );
              }

              // Build List
              return RefreshIndicator(
                onRefresh: () async {
                  await controller.syncAnnouncements();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ann = filtered[index];
                    return _announcementItem(context, ann);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String text) {
    final bool isActive = activeFilter == text;
    return GestureDetector(
      onTap: () => setState(() => activeFilter = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? primaryBlue : Colors.grey.shade300),
        ),
        child: Text(text, style: TextStyle(color: isActive ? Colors.white : darkText, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _announcementItem(BuildContext context, AnnouncementModel ann) {
    // Mengecek apakah pengumuman penting
    final bool isHighlight = ann.isImportant;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 8, offset: const Offset(0, 2), color: Colors.black.withOpacity(0.04))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Pindah ke Halaman Detail
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnnouncementDetailPage(announcement: ann)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Indikator Oranye aktif jika isImportant = true
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: isHighlight ? accentOrange : Colors.grey.shade300, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(ann.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    // Icon otomatis berubah menjadi Alert jika penting
                    Icon(isHighlight ? Icons.error_outline : Icons.info_outline, color: isHighlight ? accentOrange : Colors.grey, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(ann.isi, style: TextStyle(color: darkText.withOpacity(0.6), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ann.createdAt.toString().substring(0, 10), 
                      style: const TextStyle(fontSize: 11, color: Colors.grey)
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        // Jika array kategori kosong, tampilkan Target Audience
                        ann.kategori.isNotEmpty ? ann.kategori.join(', ') : ann.targetAudience.replaceAll('_', ' '), 
                        style: TextStyle(fontSize: 10, color: primaryBlue, fontWeight: FontWeight.bold)
                      ),
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