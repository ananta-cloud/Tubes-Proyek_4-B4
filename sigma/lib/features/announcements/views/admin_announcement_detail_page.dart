import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sigma/data/models/announcement_model.dart';
import '../../admin_tu/main/views/admin_main_page.dart';

class AdminAnnouncementDetailPage extends StatelessWidget {
  final AnnouncementModel announcement;
  const AdminAnnouncementDetailPage({super.key, required this.announcement});

  static const _kategoriColors = <String, Color>{
    'Akademik': SigmaColors.navy,
    'Beasiswa': SigmaColors.success,
    'Lomba': Color(0xFFF59E0B),
    'UKM': Color(0xFF8B5CF6),
    'Karir': Color(0xFF0EA5E9),
    'Penelitian': Color(0xFF059669),
    'Pengabdian': Color(0xFFD97706),
    'Pengajaran': Color(0xFF7C3AED),
  };

  static const _tingkatColors = <String, Color>{
    'BIASA': SigmaColors.textSub,
    'PENTING': Color(0xFFF59E0B),
    'SANGAT PENTING': SigmaColors.danger,
  };

  static const _tingkatIcons = <String, IconData>{
    'BIASA': Icons.info_outline_rounded,
    'PENTING': Icons.warning_amber_rounded,
    'SANGAT PENTING': Icons.error_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final kategori = announcement.kategori.isNotEmpty
        ? announcement.kategori.first
        : 'Umum';
    final kategoriColor = _kategoriColors[kategori] ?? SigmaColors.accent;
    final tingkatColor =
        _tingkatColors[announcement.tingkatKepentingan] ?? SigmaColors.textSub;
    final tingkatIcon =
        _tingkatIcons[announcement.tingkatKepentingan] ??
        Icons.info_outline_rounded;
    final tanggal = DateFormat(
      'd MMMM yyyy, HH:mm',
      'id_ID',
    ).format(announcement.createdAt);

    return Scaffold(
      backgroundColor: SigmaColors.bgPage,
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: SigmaColors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 14,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SigmaColors.bgPage,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: SigmaColors.navy,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Detail Pengumuman',
                    style: TextStyle(
                      color: SigmaColors.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Card Utama ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SigmaColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SigmaColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori + Tingkat
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kategoriColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                kategori,
                                style: TextStyle(
                                  color: kategoriColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tingkatColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    tingkatIcon,
                                    color: tingkatColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    announcement.tingkatKepentingan,
                                    style: TextStyle(
                                      color: tingkatColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Judul
                        Text(
                          announcement.judul,
                          style: const TextStyle(
                            color: SigmaColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Meta info
                        // ✅ SESUDAH - dua baris terpisah, tidak akan overflow
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_outline_rounded,
                                  size: 13,
                                  color: SigmaColors.textSub,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Target: ${announcement.targetAudience}',
                                  style: const TextStyle(
                                    color: SigmaColors.textSub,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: SigmaColors.textSub,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    tanggal,
                                    style: const TextStyle(
                                      color: SigmaColors.textSub,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 13,
                              color: SigmaColors.textSub,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Oleh: ${announcement.namaPublisher}',
                              style: const TextStyle(
                                color: SigmaColors.textSub,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: SigmaColors.cardBorder),
                        const SizedBox(height: 16),

                        // Isi pengumuman
                        Text(
                          announcement.isi,
                          style: const TextStyle(
                            color: SigmaColors.navy,
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Lampiran ──
                  if (announcement.attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: SigmaColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: SigmaColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_file_rounded,
                                color: SigmaColors.navy,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Lampiran (${announcement.attachments.length})',
                                style: const TextStyle(
                                  color: SigmaColors.navy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...announcement.attachments.map(
                            (att) => _AttachmentItem(attachment: att),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Attachment Item ──────────────────────────────────────────────────────────
class _AttachmentItem extends StatefulWidget {
  final Map<String, dynamic> attachment;
  const _AttachmentItem({required this.attachment});

  @override
  State<_AttachmentItem> createState() => _AttachmentItemState();
}

class _AttachmentItemState extends State<_AttachmentItem> {
  bool _imageExpanded = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.attachment['name'] ?? 'File';
    final type = widget.attachment['type'] ?? 'file';
    final data = widget.attachment['data'] ?? '';
    final sizeStr = widget.attachment['size'] ?? '0';
    final sizeKb = (int.tryParse(sizeStr) ?? 0) / 1024;

    final isImage = ['png', 'jpg', 'jpeg'].contains(type.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: SigmaColors.bgPage,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SigmaColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row info file
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isImage
                      ? Icons.image_outlined
                      : Icons.picture_as_pdf_outlined,
                  color: isImage ? SigmaColors.accent : SigmaColors.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: SigmaColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${sizeKb.toStringAsFixed(1)} KB',
                        style: const TextStyle(
                          color: SigmaColors.textSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol expand/collapse untuk gambar
                if (isImage && data.isNotEmpty)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _imageExpanded = !_imageExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: SigmaColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _imageExpanded ? 'Tutup' : 'Lihat',
                        style: const TextStyle(
                          color: SigmaColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Label PDF (tidak bisa preview)
                if (!isImage)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: SigmaColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PDF',
                      style: TextStyle(
                        color: SigmaColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Preview gambar (expand)
          if (isImage && _imageExpanded && data.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
              child: Image.memory(
                base64Decode(data),
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Gagal memuat gambar.',
                    style: TextStyle(color: SigmaColors.danger),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
