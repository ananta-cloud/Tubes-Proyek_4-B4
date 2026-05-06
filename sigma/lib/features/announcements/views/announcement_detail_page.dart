import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/data/models/announcement_model.dart';
import 'package:sigma/features/announcements/viewmodels/announcement_viewmodel.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final AnnouncementModel announcement;
  const AnnouncementDetailPage({super.key, required this.announcement});

  static const primaryBlue  = Color(0xFF3F5DB3);
  static const accentOrange = Color(0xFFFF7A36);
  static const bgColor      = Color(0xFFEAF3FA);
  static const darkText     = Color(0xFF1F1F3D);

  @override
  Widget build(BuildContext context) {
    // Memanggil ViewModel gabungan kita
    final vm = context.watch<AnnouncementViewModel>();
    final isBookmarked = vm.isBookmarked(announcement.id);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ================= HEADER DENGAN BOOKMARK =================
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? accentOrange : Colors.white,
                  size: 26,
                ),
                onPressed: () => vm.toggleBookmark(announcement, context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, right: 16, bottom: 16),
              title: const Text(
                "Detail Pengumuman",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryBlue, Color(0xFF2A3F80)],
                  ),
                ),
                child: const Stack(
                  children: [
                    Positioned(
                      right: -15,
                      bottom: -10,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(Icons.campaign_rounded, size: 110, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= AREA KONTEN =================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- KARTU INFORMASI UTAMA ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Menggunakan Helper Format Teks dari ViewModel
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                vm.formatAudience(announcement.targetAudience),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue),
                              ),
                            ),
                            // Menggunakan Helper Format Tanggal dari ViewModel
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  vm.formatDate(announcement.createdAt),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: accentOrange.withOpacity(0.1),
                              child: const Icon(Icons.person, size: 20, color: accentOrange),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Diterbitkan oleh:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(
                                  announcement.namaPublisher,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkText),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- KARTU ISI PENGUMUMAN ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (announcement.kategori.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Wrap(
                              spacing: 8,
                              children: announcement.kategori.map((kat) {
                                return Text("#$kat", style: const TextStyle(color: accentOrange, fontWeight: FontWeight.bold, fontSize: 13));
                              }).toList(),
                            ),
                          ),
                        Text(
                          announcement.judul,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          announcement.isi,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Spasi bawah
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}