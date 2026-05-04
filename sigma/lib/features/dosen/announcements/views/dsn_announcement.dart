import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/announcement_viewmodel.dart';
import '../widgets/announcement_widget.dart';

class DosenAnnouncementPage extends StatelessWidget {
  const DosenAnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajemen Pengumuman"),
        backgroundColor: const Color(0xFF2A3F80), // Warna biru lebih gelap untuk Dosen
        foregroundColor: Colors.white,
      ),
      body: vm.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.announcements.length,
            itemBuilder: (context, index) {
              final item = vm.announcements[index];
              return AnnouncementCard(
                announcement: item,
                isLecturer: true, // Untuk menampilkan indikator khusus dosen
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigasi ke halaman Buat Pengumuman (CreateAnnouncementPage)
        },
        backgroundColor: const Color(0xFFFF7A36), // Warna aksen oranye
        icon: const Icon(Icons.add),
        label: const Text("Buat Pengumuman"),
      ),
    );
  }
}