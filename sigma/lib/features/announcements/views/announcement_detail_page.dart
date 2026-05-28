import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sigma/data/models/announcement_model.dart';
import 'package:sigma/features/announcements/viewmodels/announcement_viewmodel.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final AnnouncementModel announcement;
  const AnnouncementDetailPage({super.key, required this.announcement});

  static const primaryBlue = Color(0xFF3F5DB3);
  static const accentOrange = Color(0xFFFF7A36);
  static const bgColor = Color(0xFFEAF3FA);
  static const darkText = Color(0xFF1F1F3D);

  // ==========================================================
  // FUNGSI 1: BUKA LANGSUNG (Tanpa simpan permanen / pakai Cache)
  // ==========================================================
  Future<void> _openFileDirectly(BuildContext context, String base64Data, String fileName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Membuka $fileName..."), duration: const Duration(seconds: 1)),
      );

      String cleanBase64 = base64Data;
      if (cleanBase64.contains(',')) cleanBase64 = cleanBase64.split(',').last;
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      int pad = cleanBase64.length % 4;
      if (pad > 0) cleanBase64 += '=' * (4 - pad);
      String safeFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final bytes = base64Decode(cleanBase64);

      // Gunakan folder TEMPORARY (Cache) agar tidak membebani memori HP
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/$safeFileName';
      final File file = File(filePath);
      
      await file.writeAsBytes(bytes);
      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada aplikasi untuk membuka file ini."), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuka file: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================================
  // FUNGSI 2: UNDUH PERMANEN (Simpan ke Penyimpanan HP)
  // ==========================================================
  Future<void> _downloadFile(BuildContext context, String base64Data, String fileName) async {
    try {
      bool hasPermission = false;
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (status.isGranted) hasPermission = true;
        else {
          var photosStatus = await Permission.photos.request();
          if (photosStatus.isGranted) hasPermission = true;
          else {
            var manageStatus = await Permission.manageExternalStorage.request();
            if (manageStatus.isGranted) hasPermission = true;
          }
        }
      } else {
        hasPermission = true;
      }

      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Izin ditolak! Buka pengaturan untuk memberi izin."),
              backgroundColor: Colors.red,
              action: SnackBarAction(label: "PENGATURAN", textColor: Colors.white, onPressed: () => openAppSettings()),
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mengunduh $fileName..."), duration: const Duration(seconds: 1)),
        );
      }

      String cleanBase64 = base64Data;
      if (cleanBase64.contains(',')) cleanBase64 = cleanBase64.split(',').last;
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      int pad = cleanBase64.length % 4;
      if (pad > 0) cleanBase64 += '=' * (4 - pad);
      String safeFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final bytes = base64Decode(cleanBase64);

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory(); 
      }

      if (directory != null) {
        final filePath = '${directory.path}/$safeFileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Berhasil diunduh! ($safeFileName)"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: "BUKA FILE",
                textColor: Colors.white,
                onPressed: () => OpenFilex.open(file.path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengunduh: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

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
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
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
              titlePadding: const EdgeInsets.only(
                left: 48,
                right: 16,
                bottom: 16,
              ),
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
                        child: Icon(
                          Icons.campaign_rounded,
                          size: 110,
                          color: Colors.white,
                        ),
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
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                vm.formatAudience(announcement.targetAudience),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                            // Menggunakan Helper Format Tanggal dari ViewModel
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  vm.formatDate(announcement.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
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
                              child: const Icon(
                                Icons.person,
                                size: 20,
                                color: accentOrange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Diterbitkan oleh:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  announcement.namaPublisher,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
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
                                return Text(
                                  "#$kat",
                                  style: const TextStyle(
                                    color: accentOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        Text(
                          announcement.judul,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          announcement.isi,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade800,
                            height: 1.7,
                          ),
                        ),
                        if (announcement.attachments.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Divider(
                            color: Color(0xFFEAF3FA),
                            thickness: 1.5,
                          ), // Garis pemisah opsional
                          const SizedBox(height: 16),
                          const Text(
                            "Lampiran",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ...announcement.attachments.map((attachment) {
                            final String type = attachment['type']?.toString() ?? '';
                            final String base64Data = attachment['data']?.toString() ?? '';
                            final String name = attachment['name']?.toString() ?? 'Lampiran';

                            final isImage = type.toLowerCase() == 'jpg' || 
                                            type.toLowerCase() == 'jpeg' || 
                                            type.toLowerCase() == 'png';

                            if (isImage && base64Data.isNotEmpty) {
                              try {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Stack(
                                    children: [
                                      InkWell(
                                        onTap: () => _openFileDirectly(context, base64Data, name),
                                        borderRadius: BorderRadius.circular(12),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.memory(
                                            base64Decode(base64Data),
                                            width: double.infinity,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) => const Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: Text("Gagal memuat gambar", style: TextStyle(color: Colors.red)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 8,
                                        bottom: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black.withOpacity(0.5),
                                          child: IconButton(
                                            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                                            onPressed: () => _downloadFile(context, base64Data, name),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                return const Text("Format gambar tidak valid.");
                              }
                            }
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: primaryBlue.withOpacity(0.1)),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _openFileDirectly(context, base64Data, name),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.insert_drive_file, color: primaryBlue, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              color: primaryBlue, 
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.download_rounded, color: primaryBlue, size: 22),
                                          onPressed: () => _downloadFile(context, base64Data, name),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
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
