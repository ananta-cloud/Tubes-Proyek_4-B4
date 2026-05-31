import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import '../viewmodels/announcement_viewmodel.dart';
import 'announcement_detail_page.dart';
import '../widgets/announcement_widget.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari LoginViewModel untuk cek Role
    final authVm = context.watch<LoginViewModel>();
    final isLecturer = authVm.user?.role.toUpperCase() == 'DOSEN';

    // Ambil data pengumuman
    final vm = context.watch<AnnouncementViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isLecturer ? "Manajemen Pengumuman" : "Pengumuman Kampus"),
        // Warna berdasarkan Role
        backgroundColor: isLecturer
            ? const Color(0xFF2A3F80)
            : const Color(0xFF3F5DB3),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterList(vm),

          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: vm.syncAnnouncements,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vm.announcements.length,
                      itemBuilder: (context, index) {
                        final item = vm.announcements[index];
                        return AnnouncementCard(
                          announcement: item,
                          isLecturer: isLecturer,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AnnouncementDetailPage(announcement: item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      // FAB HANYA muncul untuk Dosen
      floatingActionButton: isLecturer
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreatePage(context),
              backgroundColor: const Color(0xFFFF7A36),
              icon: const Icon(Icons.add),
              label: const Text("Buat Pengumuman"),
            )
          : null,
    );
  }

  // Fungsi navigasi khusus dosen
  void _navigateToCreatePage(BuildContext context) {
    // Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAnnouncementPage()));
  }

  Widget _buildFilterList(AnnouncementViewModel vm) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: vm.filters.length,
        itemBuilder: (context, index) {
          final filter = vm.filters[index];
          final isSelected = vm.selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => vm.setFilter(filter),
              selectedColor: const Color(0xFF3F5DB3),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }
}
