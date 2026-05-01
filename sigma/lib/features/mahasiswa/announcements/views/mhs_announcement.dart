import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/announcement_viewmodel.dart';
import 'announcement_detail_page.dart';
import '../widgets/announcement_widget.dart';

class MahasiswaAnnouncementPage extends StatelessWidget {
  const MahasiswaAnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengumuman Kampus"),
        backgroundColor: const Color(0xFF3F5DB3),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Horizontal
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
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AnnouncementDetailPage(announcement: item)),
                        ),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
    );
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
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
            ),
          );
        },
      ),
    );
  }
}