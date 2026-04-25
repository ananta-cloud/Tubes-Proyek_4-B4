import 'package:flutter/material.dart';

class BookmarksDosen extends StatelessWidget {
  const BookmarksDosen({super.key});

  final Color darkText = const Color(0xFF1F1F3D);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          "Tersimpan",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 20),
        _announcementItem(
          "Panduan Penggunaan Logbook",
          "Dokumentasi sinkronisasi cloud untuk logbook.",
          false,
        ),
      ],
    );
  }

  Widget _announcementItem(String title, String desc, bool important) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(Icons.bookmark, color: Color(0xFF3F5DB3), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(color: darkText.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
