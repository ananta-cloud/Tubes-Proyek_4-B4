import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/task_form_viewmodel.dart';
import '../../../../data/models/task_model.dart';
import '../../../auth/viewmodels/login_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/dosen_model.dart';
import '../../../../core/network/mongo_database.dart';
import 'package:mongo_dart/mongo_dart.dart' show where;
import 'package:hive/hive.dart';
import 'package:sigma/shared/app_colors.dart';

class TaskFormPage extends StatefulWidget {
  final TaskModel? taskToEdit;

  const TaskFormPage({super.key, this.taskToEdit});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  // Warna Tema SIGMA
  static const secondaryBlue = Color(0xFF3F5DB3);
  static const accentOrange = Color(0xFFFF7A36);
  static const navyDark = Color(0xFF1F1F3D);

  late TaskFormViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = Provider.of<TaskFormViewModel>(context, listen: false);

    // 💡 BUNGKUS SEMUANYA DI DALAM POST FRAME CALLBACK
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Setup form
      if (widget.taskToEdit != null) {
        _viewModel.initializeForEdit(widget.taskToEdit!);
      } else {
        _viewModel.clearForm();
      }

      // Load data dosen
      final user = context.read<LoginViewModel>().user;
      if (user != null && mounted) {
        _loadDosenOfflineFirst(user);
      }
    });
  }

  Future<void> _loadDosenOfflineFirst(user) async {
    try {
      final box = Hive.box<DosenModel>('dosen_box');

      // 1. CARI DI LOKAL DULU (Pasti sangat cepat & bisa tanpa internet)
      final localDosen = box.values
          .where(
            (d) =>
                d.email.trim().toLowerCase() == user.email.trim().toLowerCase(),
          )
          .toList();

      if (localDosen.isNotEmpty) {
        final dosen = localDosen.first;
        print("⚡ [LOKAL] Profil dosen dimuat dari Hive: ${dosen.namaDosen}");

        // Langsung tampilkan di UI!
        _viewModel.loadPengajaran(dosen, taskToEdit: widget.taskToEdit);

        // Lakukan sinkronisasi diam-diam ke MongoDB di background
        _syncDosenFromMongoBackground(user.email, box);
      } else {
        // 2. JIKA DI LOKAL KOSONG, PAKSA TARIK DARI MONGODB
        print(
          "☁️ [CLOUD] Cache kosong. Mencoba menarik profil dosen dari MongoDB...",
        );
        await _syncDosenFromMongoBackground(
          user.email,
          box,
          forceLoadToUI: true,
        );
      }
    } catch (e) {
      print("⚠️ Error Offline-First Dosen: $e");
    }
  }

  Future<void> _syncDosenFromMongoBackground(
    String email,
    Box<DosenModel> box, {
    bool forceLoadToUI = false,
  }) async {
    try {
      final dosenDoc = await MongoDatabase.runSafe(
        () => MongoDatabase.dosenCollection.findOne(where.eq('email', email)),
      );

      if (dosenDoc != null) {
        final dosen = DosenModel.fromMongo(dosenDoc);

        await box.put(dosen.id, dosen);

        if (forceLoadToUI) {
          print(
            "✅ [CLOUD] Dosen ditarik & disimpan ke lokal: ${dosen.namaDosen} (Kode: ${dosen.kodeDosen})",
          );
          _viewModel.loadPengajaran(dosen, taskToEdit: widget.taskToEdit);
        } else {
          print(
            "🔄 [SYNC] Cache profil dosen berhasil diperbarui di background.",
          );
        }
      } else {
        print(
          "❌ [CLOUD] Dosen dengan email '$email' tidak ditemukan di database MongoDB.",
        );
      }
    } catch (e) {
      print("🔌 [ERROR MONGO] Gagal menarik data dari server: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // =========================================================================
  // FUNGSI PICK FILE (Langsung Menambahkan File Tanpa Dialog)
  // =========================================================================
  Future<void> _pickFile() async {
    try {
      // Memanggil fungsi baru yang menangani Base64 sekaligus memvalidasi ukuran
      final errorMsg = await _viewModel.pickFileAndConvert();
      
      // Jika ada error (ukuran lebih dari 5MB atau gagal baca)
      if (errorMsg != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat memilih file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================================
  // FUNGSI PREVIEW LAMPIRAN
  // =========================================================================
  void _previewAttachment(String uriString, String fileName) async {
    if (uriString.isEmpty) return;

    final isImage = fileName.toLowerCase().endsWith('.png') ||
                    fileName.toLowerCase().endsWith('.jpg') ||
                    fileName.toLowerCase().endsWith('.jpeg');

    if (isImage) {
      // Tampilkan popup Image Preview
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: uriString.startsWith('http')
                    ? Image.network(uriString, fit: BoxFit.contain)
                    : Image.file(File(uriString), fit: BoxFit.contain),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Jika bukan gambar (misal PDF)
      if (uriString.startsWith('http')) {
        final Uri url = Uri.parse(uriString);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Preview untuk dokumen lokal ($fileName) tidak tersedia. File akan dapat diakses setelah tugas disimpan."),
            backgroundColor: accentOrange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.taskToEdit != null;
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: navyDark,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEditMode ? "Edit Tugas" : "Buat Tugas Baru",
            style: const TextStyle(
              color: navyDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<TaskFormViewModel>(
          builder: (context, viewModel, child) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _viewModel.namaTugasController,
                  decoration: InputDecoration(
                    labelText: "Nama Tugas",
                    prefixIcon: const Icon(
                      Icons.edit_document,
                      color: secondaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                viewModel.availableKelasList.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "Silakan pilih mata kuliah terlebih dahulu.",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : TextField(
                        controller: _viewModel.deskripsiController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Deskripsi Tugas (Opsional)",
                          prefixIcon: const Icon(
                            Icons.description,
                            color: secondaryBlue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),

                // =========================================================================
                // DROPDOWN 1: PILIH MATA KULIAH
                // =========================================================================
                Consumer<TaskFormViewModel>(
                  builder: (context, viewModel, _) {
                    if (viewModel.isLoadingPengajaran) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: secondaryBlue,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Memuat data pengajaran...",
                              style: TextStyle(color: secondaryBlue),
                            ),
                          ],
                        ),
                      );
                    }

                    return InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Mata Kuliah",
                        prefixIcon: const Icon(
                          Icons.book,
                          color: secondaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value:
                              viewModel.uniqueMatkulList.contains(
                                viewModel.selectedMatkulDisplay,
                              )
                              ? viewModel.selectedMatkulDisplay
                              : null,
                          hint: Text(
                            viewModel.uniqueMatkulList.isEmpty
                                ? "Belum ada kelas yang Anda ajar"
                                : "Pilih Mata Kuliah",
                          ),
                          items: viewModel.uniqueMatkulList.map((matkulString) {
                            return DropdownMenuItem<String>(
                              value: matkulString,
                              child: Text(matkulString),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            viewModel.selectMatkul(newValue);
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // =========================================================================
                // DROPDOWN 2: PILIH TARGET KELAS
                // =========================================================================
                Consumer<TaskFormViewModel>(
                  builder: (context, viewModel, _) {
                    final bool isMatkulSelected =
                        viewModel.selectedMatkulDisplay != null;

                    return InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Target Kelas (Bisa pilih lebih dari 1)",
                        prefixIcon: Icon(
                          Icons.class_outlined,
                          color: isMatkulSelected ? secondaryBlue : Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: !isMatkulSelected,
                        fillColor: isMatkulSelected
                            ? Colors.transparent
                            : Colors.grey.shade100,
                      ),
                      child: !isMatkulSelected
                          ? const Text(
                              "Pilih mata kuliah terlebih dahulu",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            )
                          : Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0, 
                              children: viewModel.availableKelasList.map((
                                kelas,
                              ) {
                                final isSelected = viewModel.selectedTargetKelas
                                    .contains(kelas);
                                return FilterChip(
                                  label: Text(kelas),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    viewModel.toggleKelas(kelas);
                                  },
                                  selectedColor: secondaryBlue,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: Colors.grey.shade200,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : navyDark,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                );
                              }).toList(),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final initial = viewModel.selectedDeadline ?? now;
                    
                    // Mencegah crash: Jika deadline sebelumnya sudah lewat dari hari ini,
                    // maka firstDate mundur ke tanggal deadline sebelumnya.
                    final first = initial.isBefore(now) ? initial : now;

                    final date = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: first, 
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(initial),
                      );
                      if (time != null) {
                        viewModel.setDeadline(DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ));
                      }
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Deadline Tugas",
                      prefixIcon: const Icon(
                        Icons.access_time_filled,
                        color: accentOrange,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      viewModel.selectedDeadline != null
                          ? "${viewModel.selectedDeadline!.day.toString().padLeft(2, '0')}/${viewModel.selectedDeadline!.month.toString().padLeft(2, '0')}/${viewModel.selectedDeadline!.year} - ${viewModel.selectedDeadline!.hour.toString().padLeft(2, '0')}:${viewModel.selectedDeadline!.minute.toString().padLeft(2, '0')}"
                          : "Pilih Tanggal & Waktu",
                      style: TextStyle(
                        color: viewModel.selectedDeadline != null
                            ? navyDark
                            : Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // =========================================================================
                // LAMPIRAN SECTION
                // =========================================================================
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Lampiran File",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: navyDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file, size: 14),
                      label: const Text("Pilih Dokumen / Gambar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Lampiran List
                if (viewModel.lampiran.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Daftar Lampiran:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: navyDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: viewModel.lampiran.length,
                          itemBuilder: (context, index) {
                            final attachment = viewModel.lampiran[index];
                            final fileName = attachment['title'] ?? 'File';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              elevation: 1,
                              child: ListTile(
                                dense: true,
                                // FUNGSI PREVIEW LAMPIRAN
                                onTap: () => _previewAttachment(attachment['uri'] ?? '', fileName),
                                leading: const Icon(
                                  Icons.insert_drive_file,
                                  size: 18,
                                  color: secondaryBlue
                                ),
                                title: Text(
                                  fileName,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: const Text(
                                  'Tap untuk melihat',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                trailing: SizedBox(
                                  width: 36,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        viewModel.removeAttachment(index),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        "Belum ada file yang dipilih",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (_viewModel.namaTugasController.text.isNotEmpty &&
                    _viewModel.selectedDeadline != null &&
                    _viewModel.selectedTargetKelas.isNotEmpty) {
                  // KITA AMBIL SELURUH OBJEK USER LENGKAP
                  final currentUser = context.read<LoginViewModel>().user;
                  if (currentUser == null) return;

                  bool success;
                  if (isEditMode) {
                    success = await _viewModel.updateTaskForStudents(
                      widget.taskToEdit!,
                      currentUser,
                    );
                  } else {
                    success = await _viewModel.createTaskForStudents(
                      currentUser,
                    );
                  }

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditMode
                              ? "Tugas berhasil diperbarui!"
                              : "Tugas berhasil dibuat!",
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Gagal menyimpan tugas. Periksa koneksi internet.",
                        ),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Nama Tugas, Mata Kuliah, Kelas, & Deadline wajib diisi!",
                      ),
                    ),
                  );
                }
              },
              child: Text(
                isEditMode ? "Simpan Perubahan" : "Buat Tugas",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}