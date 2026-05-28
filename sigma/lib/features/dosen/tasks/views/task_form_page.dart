import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:file_picker/file_picker.dart';
import '../viewmodels/task_form_viewmodel.dart';
import '../../../../data/models/task_model.dart';
import '../../../auth/viewmodels/login_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sigma/shared/app_colors.dart';

class TaskFormPage extends StatefulWidget {
  final TaskModel? taskToEdit;

  const TaskFormPage({super.key, this.taskToEdit});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  // Warna Tema SIGMA
  // static const navyDark = Color(0xFF1F1F3D);
  static const secondaryBlue = Color(0xFF3F5DB3);

  // static const bgColor = Color(0xFFEAF3FA);

  late TaskFormViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TaskFormViewModel();
    _viewModel.initializeForEdit(widget.taskToEdit);

    final user = context.read<LoginViewModel>().user;
    if (user != null) {
      String cleanId = user.id
          .replaceAll('ObjectId("', '')
          .replaceAll('")', '');

      // Mengirimkan parameter taskToEdit agar form bisa auto-select dropdown saat mode edit
      _viewModel.loadPengajaran(cleanId, taskToEdit: widget.taskToEdit);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final file = await _viewModel.pickFile(); // Mengambil PlatformFile

      if (file != null) {
        final fileName = file.name;
        final fileSizeInBytes = file.size; // Aman untuk Web & Mobile
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        print(
          '📎 File picked: $fileName, Size: ${fileSizeInMB.toStringAsFixed(2)}MB',
        );

        if (fileSizeInMB > 5) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ukuran file maksimal 5MB (${fileSizeInMB.toStringAsFixed(2)}MB)',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }

        // Web tidak memiliki 'path' absolut, maka gunakan fallback
        final filePath = file.path ?? 'Web_File_$fileName';
        _showAddAttachmentDialog('File', fileName, filePath);
      }
    } catch (e) {
      print('❌ Error picking file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membaca file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddAttachmentDialog(
    String type,
    String? initialTitle,
    String? initialUri,
  ) {
    final titleController = TextEditingController(text: initialTitle ?? '');
    final uriController = TextEditingController(text: initialUri ?? '');
    String selectedType = type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Lampiran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Tipe Lampiran'),
                items: ['File', 'Link'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedType = value!);
                },
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              TextField(
                controller: uriController,
                decoration: InputDecoration(
                  labelText: selectedType == 'File' ? 'Path File' : 'URL Link',
                ),
                readOnly: selectedType == 'File',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    uriController.text.isNotEmpty) {
                  _viewModel.addAttachment(
                    selectedType.toLowerCase(),
                    titleController.text,
                    uriController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
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
              color: AppColors.navyDark,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEditMode ? "Edit Tugas" : "Buat Tugas Baru",
            style: const TextStyle(
              color: AppColors.navyDark,
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
                  controller: viewModel.namaTugasController,
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

                TextField(
                  controller: viewModel.deskripsiController,
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
                          value: viewModel.selectedMatkulDisplay,
                          hint: Text(
                            viewModel.uniqueMatkulList.isEmpty
                                ? "Belum ada kelas yang Anda ajar"
                                : "Pilih Mata Kuliah",
                          ),
                          items: viewModel.uniqueMatkulList.map((matkulString) {
                            return DropdownMenuItem<String>(
                              value: matkulString,
                              child: Text(
                                matkulString,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: viewModel.uniqueMatkulList.isEmpty
                              ? null
                              : (String? newValue) {
                                  viewModel.selectMatkul(newValue);
                                },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // =========================================================================
                // DROPDOWN 2: PILIH TARGET KELAS (AKAN AKTIF JIKA DROPDOWN 1 SUDAH DIPILIH)
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
                              spacing: 8.0, // Jarak antar tombol ke samping
                              runSpacing: 4.0, // Jarak antar tombol ke bawah
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
                                        : AppColors.navyDark,
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
                    final date = await showDatePicker(
                      context: context,
                      initialDate: viewModel.selectedDeadline ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          viewModel.selectedDeadline ?? DateTime.now(),
                        ),
                      );
                      if (time != null) {
                        setState(() {
                          viewModel.selectedDeadline = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Deadline Tugas",
                      prefixIcon: const Icon(
                        Icons.access_time_filled,
                        color: AppColors.gold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      viewModel.selectedDeadline != null
                          ? "${viewModel.selectedDeadline!.day}/${viewModel.selectedDeadline!.month}/${viewModel.selectedDeadline!.year} - ${viewModel.selectedDeadline!.hour.toString().padLeft(2, '0')}:${viewModel.selectedDeadline!.minute.toString().padLeft(2, '0')}"
                          : "Pilih Tanggal & Waktu",
                      style: TextStyle(
                        color: viewModel.selectedDeadline != null
                            ? AppColors.navyDark
                            : Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Lampiran Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Lampiran",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file, size: 14),
                            label: const Text("File"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showAddAttachmentDialog('Link', null, null),
                            icon: const Icon(Icons.link, size: 14),
                            label: const Text("Link"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
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
                          color: AppColors.navyDark,
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              elevation: 1,
                              child: ListTile(
                                dense: true,
                                // =======================================================
                                // FUNGSI BARU: ON TAP UNTUK PREVIEW / DOWNLOAD
                                // =======================================================
                                onTap: () async {
                                  final uriString = attachment['uri'] ?? '';
                                  if (uriString.isEmpty) return;

                                  // Cek apakah ini link web / file dari server (http/https)
                                  if (uriString.startsWith('http')) {
                                    final Uri url = Uri.parse(uriString);
                                    if (await canLaunchUrl(url)) {
                                      // Buka di browser bawaan HP
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Tidak dapat membuka tautan ini.",
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    // Jika ini file lokal yang baru saja dipilih (belum di-upload)
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "📄 Ini adalah draf file lokal Anda. Preview/Download akan tersedia setelah Anda menyimpan tugas ini.",
                                        ),
                                        duration: Duration(seconds: 3),
                                        backgroundColor: AppColors.accent,
                                      ),
                                    );
                                  }
                                },

                                // =======================================================
                                leading: Icon(
                                  attachment['type'] == 'file'
                                      ? Icons.insert_drive_file
                                      : Icons.link,
                                  size: 18,
                                  color: attachment['type'] == 'file'
                                      ? secondaryBlue
                                      : AppColors.gold,
                                ),
                                title: Text(
                                  attachment['title'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  attachment['type'] == 'file'
                                      ? 'File'
                                      : 'Link',
                                  style: const TextStyle(fontSize: 11),
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
                        "Belum ada lampiran",
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
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // UBAH BAGIAN INI MENJADI .isNotEmpty
                if (_viewModel.namaTugasController.text.isNotEmpty &&
                    _viewModel.selectedDeadline != null &&
                    _viewModel.selectedTargetKelas.isNotEmpty) {
                  final userId = context.read<LoginViewModel>().user?.id ?? "";

                  bool success;
                  if (isEditMode) {
                    success = await _viewModel.updateTaskForStudents(
                      widget.taskToEdit!,
                    );
                  } else {
                    success = await _viewModel.createTaskForStudents(userId);
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
