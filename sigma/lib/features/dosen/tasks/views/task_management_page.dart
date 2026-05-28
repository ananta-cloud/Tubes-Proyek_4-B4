import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/group_task_model.dart';
import '../../../../data/models/pengajaran_model.dart';
import '../../../../data/services/task_service.dart';
import '../../../auth/viewmodels/login_viewmodel.dart';
import 'task_form_page.dart';

class TaskManagementPage extends StatefulWidget {
  const TaskManagementPage({super.key});

  @override
  State<TaskManagementPage> createState() => _TaskManagementPageState();
}

class _TaskManagementPageState extends State<TaskManagementPage> {
  static const primaryBlue = Color(0xFF1F1F3D);
  static const secondaryBlue = Color(0xFF3F5DB3);
  static const accentOrange = Color(0xFFFF7A36);

  late Box<TaskModel> _taskBox;
  final TaskService _taskService = TaskService();
  List<String> _selectedFilterMatkul = [];

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<TaskModel>('tasks');
    _syncDataFromServer();
  }

  List<GroupedTask> dapatkanTugasTerkelompok(List<TaskModel> rawTasks) {
    final Map<String, GroupedTask> groups = {};

    for (var task in rawTasks) {
      String snapshot = task.namaMkSnapshot ?? 'Umum';
      String matkulName = snapshot;
      String kelas = '';

      // Ekstrak nama kelas dari snapshot
      if (snapshot.contains('(')) {
        int openBracket = snapshot.lastIndexOf('(');
        matkulName = snapshot.substring(0, openBracket).trim();
        kelas = snapshot
            .substring(openBracket + 1, snapshot.lastIndexOf(')'))
            .trim();
      }

      // Jika field kelas di model sudah tersimpan, gunakan itu sebagai prioritas
      if (task.kelas != null && task.kelas!.isNotEmpty) {
        kelas = task.kelas!;
      }

      String timeKey =
          "${task.deadline.year}-${task.deadline.month}-${task.deadline.day}_${task.deadline.hour}:${task.deadline.minute}";
      String key = "${task.idMk}_${timeKey}_${task.namaTugas}";

      if (groups.containsKey(key)) {
        // Jika grup sudah ada (tugas & deadline sama), cukup tambahkan kelasnya!
        if (kelas.isNotEmpty && !groups[key]!.targetKelasList.contains(kelas)) {
          groups[key]!.targetKelasList.add(kelas);
        }
        groups[key]!.originalTasks.add(task);
      } else {
        // Jika belum ada / deadline berbeda, buat kartu tugas baru!
        groups[key] = GroupedTask(
          baseId: task.id,
          namaTugas: task.namaTugas,
          deskripsi: task.deskripsi,
          idMk: task.idMk,
          matkulNamaSaja: matkulName,
          targetKelasList: kelas.isNotEmpty ? [kelas] : [],
          deadline: task.deadline,
          isSynced: task.isSynced,
          originalTasks: [task],
        );
      }
    }

    final groupedList = groups.values.toList();
    // Urutkan berdasarkan deadline terdekat
    groupedList.sort((a, b) => a.deadline.compareTo(b.deadline));
    return groupedList;
  }

  Set<String> get _allMataKuliah {
    final user = context.read<LoginViewModel>().user;

    // 1. Gunakan toUpperCase() agar kebal terhadap perbedaan tulisan 'Dosen' atau 'DOSEN'
    if (user == null || user.role.toUpperCase() != 'DOSEN') return {};

    final String cleanUserId = user.id
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .trim();
    final matkulSet = <String>{};

    // 2. Ambil daftar mata kuliah langsung dari tugas-tugas yang sudah pernah dibuat!
    for (final task in _taskBox.values) {
      if (task.idUser == cleanUserId && task.namaMkSnapshot != null) {
        String snapshot = task.namaMkSnapshot!;

        // Bersihkan string untuk mendapatkan nama matkul saja (menghilangkan "(2B-D3)")
        if (snapshot.contains('(')) {
          int openBracket = snapshot.lastIndexOf('(');
          matkulSet.add(snapshot.substring(0, openBracket).trim());
        } else {
          matkulSet.add(snapshot.trim());
        }
      }
    }

    return matkulSet;
  }

  List<TaskModel> get _myRawTasks {
    final userId = context.read<LoginViewModel>().user?.id ?? '';
    final String cleanId = userId
        .replaceAll('ObjectId("', '')
        .replaceAll('")', '');

    return _taskBox.values.where((task) {
      if (task.idUser != cleanId) return false;

      // Jika ada filter matkul yang dicentang (multi-select)
      if (_selectedFilterMatkul.isNotEmpty) {
        if (task.namaMkSnapshot == null) return false;

        // Cek apakah tugas ini mengandung SALAH SATU dari matkul yang dicentang
        bool matches = false;
        for (String matkul in _selectedFilterMatkul) {
          if (task.namaMkSnapshot!.contains(matkul)) {
            matches = true;
            break; // Jika ketemu satu kecocokan, langsung lolos filter
          }
        }
        return matches;
      }

      // Jika tidak ada filter yang dicentang (tombol "Semua" aktif)
      return true;
    }).toList();
  }

  Future<void> _uploadPendingTasks() async {
    try {
      final pendingTasks = _taskBox.values.where((t) => !t.isSynced).toList();
      if (pendingTasks.isEmpty) return;

      print(
        "☁️ Mengunggah ${pendingTasks.length} tugas offline secara paralel...",
      );

      // Menggunakan Future.wait agar semua request API berjalan BERSAMAAN (Paralel)
      await Future.wait(
        pendingTasks.map((task) async {
          bool success = await _taskService.updateTask(task);
          if (!success) {
            success = await _taskService.createTask(task);
          }
          if (success) {
            task.isSynced = true;
            await task.save();
          }
        }),
      );
    } catch (e) {
      print("❌ Gagal upload tugas offline: $e");
    }
  }

  Future<void> _syncDataFromServer() async {
    try {
      final user = context.read<LoginViewModel>().user;
      if (user == null) return;
      String cleanId = user.id
          .replaceAll('ObjectId("', '')
          .replaceAll('")', '');

      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOffline = (connectivityResult as List).contains(
        ConnectivityResult.none,
      );
      if (isOffline) return;
      List<Map<String, dynamic>> rawCloudTasks = await _taskService
          .getTasksByUser(cleanId);
      List<TaskModel> cloudTasks = [];
      for (var data in rawCloudTasks) {
        try {
          cloudTasks.add(TaskModel.fromMongo(data));
        } catch (_) {}
      }
      Set<String> cloudIds = cloudTasks.map((t) => t.id).toSet();
      final pendingTasks = _taskBox.values.where((t) => !t.isSynced).toList();
      bool hasNewUploads = false;

      if (pendingTasks.isNotEmpty) {
        print("☁️ Mengunggah ${pendingTasks.length} tugas offline...");
        await Future.wait(
          pendingTasks.map((task) async {
            bool success = false;

            if (cloudIds.contains(task.id)) {
              success = await _taskService.updateTask(task);
            } else {
              success = await _taskService.createTask(task);
            }

            if (success) {
              task.isSynced = true;
              await task.save();
              hasNewUploads = true;
            }
          }),
        );
      }

      if (hasNewUploads) {
        rawCloudTasks = await _taskService.getTasksByUser(cleanId);
        cloudTasks.clear();
        cloudIds.clear();
        for (var data in rawCloudTasks) {
          try {
            final t = TaskModel.fromMongo(data);
            cloudTasks.add(t);
            cloudIds.add(t.id);
          } catch (_) {}
        }
      }
      final Map<String, TaskModel> tasksToPut = {};
      final List<String> keysToDelete = [];

      // Masukkan data server ke lokal
      for (var taskFromServer in cloudTasks) {
        final localTask = _taskBox.get(taskFromServer.id);
        if (localTask == null || localTask.isSynced == true) {
          tasksToPut[taskFromServer.id] = taskFromServer;
        }
      }

      // Bersihkan data lokal yang benar-benar tidak ada di server
      final localKeys = _taskBox.keys.cast<String>().toList();
      for (var key in localKeys) {
        final taskInHive = _taskBox.get(key);
        // Hapus HANYA JIKA task sudah sukses disync TAPI tidak ada di response server
        if (taskInHive != null &&
            taskInHive.isSynced &&
            !cloudIds.contains(key)) {
          keysToDelete.add(key);
        }
      }

      // Eksekusi Massal
      if (tasksToPut.isNotEmpty) await _taskBox.putAll(tasksToPut);
      if (keysToDelete.isNotEmpty) await _taskBox.deleteAll(keysToDelete);

      if (mounted) setState(() {});
    } catch (e) {
      print("❌ Gagal Sinkronisasi: $e");
    }
  }

  void _navigateToCreateTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormPage()),
    ).then((_) => setState(() {}));
  }

  void _navigateToEditTask(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormPage(taskToEdit: task)),
    ).then((_) => setState(() {}));
  }

  Future<void> _deleteGroupedTask(GroupedTask groupedTask) async {
    final String daftarKelasText = groupedTask.targetKelasList.join(', ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: Text(
          'Apakah Anda yakin ingin menghapus tugas ini untuk seluruh kelas yang bersangkutan ($daftarKelasText)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = !(connectivityResult as List).contains(
        ConnectivityResult.none,
      );

      for (var task in groupedTask.originalTasks) {
        await _taskBox.delete(task.id);
        if (isOnline) {
          await _taskService.deleteTask(task.id);
        }
      }

      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil dihapus dari seluruh kelas!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ValueListenableBuilder<Box<TaskModel>>(
        valueListenable: _taskBox.listenable(),
        builder: (context, box, _) {
          final rawTasks = _myRawTasks;
          final groupedTasks = dapatkanTugasTerkelompok(rawTasks);
          final allMatkul = _allMataKuliah.toList()..sort();

          return Column(
            children: [
              if (allMatkul.isNotEmpty) _buildFilterBar(allMatkul),
              Expanded(
                child: RefreshIndicator(
                  // 1. Panggil fungsi sinkronisasi Anda di sini
                  onRefresh: _syncDataFromServer,
                  color: secondaryBlue,
                  backgroundColor: Colors.white,
                  child: groupedTasks.isEmpty
                      // 2. Jika kosong, gunakan SingleChildScrollView agar tetap bisa ditarik (pull)
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height:
                                MediaQuery.of(context).size.height *
                                0.6, // Sesuaikan tinggi
                            child: _buildEmptyState(),
                          ),
                        )
                      // 3. Jika ada data, bungkus ListView
                      : ListView.builder(
                          // WAJIB: Agar list bisa ditarik ke bawah meskipun jumlah item sedikit
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: groupedTasks.length,
                          itemBuilder: (context, index) {
                            return _buildGroupedTaskCard(groupedTasks[index]);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateTask,
        backgroundColor: accentOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterBar(List<String> matkulList) {
    // LOGIKA REORDER: Pisahkan matkul yang dipilih dan yang tidak
    List<String> selectedMatkuls = [];
    List<String> unselectedMatkuls = [];

    for (String m in matkulList) {
      if (_selectedFilterMatkul.contains(m)) {
        selectedMatkuls.add(m);
      } else {
        unselectedMatkuls.add(m);
      }
    }

    // Gabungkan list: Letakkan semua yang dipilih di urutan terdepan
    List<String> displayMatkul = [...selectedMatkuls, ...unselectedMatkuls];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 1. TOMBOL "SEMUA"
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  'Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    // Teks putih jika kosong (default), biru jika sedang pilih matkul
                    color: _selectedFilterMatkul.isEmpty
                        ? Colors.white
                        : secondaryBlue,
                  ),
                ),
                // Aktif jika List filter kosong
                selected: _selectedFilterMatkul.isEmpty,
                // Jika "Semua" diklik, bersihkan semua centang matkul
                onSelected: (_) =>
                    setState(() => _selectedFilterMatkul.clear()),
                backgroundColor: Colors.white,
                selectedColor: secondaryBlue,
                showCheckmark: false,
                side: BorderSide(
                  color: _selectedFilterMatkul.isEmpty
                      ? secondaryBlue
                      : Colors.grey.shade300,
                ),
              ),
            ),

            // 2. TOMBOL MATA KULIAH LAINNYA
            ...displayMatkul.map((matkul) {
              final isSelected = _selectedFilterMatkul.contains(matkul);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    matkul,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : secondaryBlue,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        // Jika sudah dipilih, hapus dari filter
                        _selectedFilterMatkul.remove(matkul);
                      } else {
                        // Jika belum dipilih, tambahkan ke filter
                        _selectedFilterMatkul.add(matkul);
                      }
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: secondaryBlue,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected ? secondaryBlue : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada tugas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat tugas pertama Anda untuk mahasiswa',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTaskCard(GroupedTask groupedTask) {
    final representatifTask = groupedTask.originalTasks.first;
    final String daftarKelasText = groupedTask.targetKelasList.join(', ');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTaskDetailBottomSheet(context, groupedTask),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      groupedTask.namaTugas,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  _buildStatusChip(representatifTask.status),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                "📚 ${groupedTask.matkulNamaSaja} (${daftarKelasText.isEmpty ? 'Semua Kelas' : daftarKelasText})",
                style: const TextStyle(
                  fontSize: 14,
                  color: secondaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${_formatDateTime(groupedTask.deadline)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              if (representatifTask.lampiran != null &&
                  representatifTask.lampiran!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${representatifTask.lampiran!.length} lampiran',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        groupedTask.isSynced
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        size: 18,
                        color: groupedTask.isSynced
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        groupedTask.isSynced
                            ? "Tersinkronisasi"
                            : "Menunggu Jaringan",
                        style: TextStyle(
                          fontSize: 11,
                          color: groupedTask.isSynced
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _navigateToEditTask(representatifTask),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: secondaryBlue,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _deleteGroupedTask(groupedTask),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Hapus'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'SELESAI':
        color = Colors.green;
        label = 'Selesai';
        break;
      case 'BELUM':
      default:
        color = accentOrange;
        label = 'Aktif';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showTaskDetailBottomSheet(
    BuildContext context,
    GroupedTask groupedTask,
  ) {
    final representatifTask = groupedTask.originalTasks.first;
    final String daftarKelasText = groupedTask.targetKelasList.join(', ');

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Agar popup bisa lebih tinggi dari setengah layar jika isinya panjang
      backgroundColor: Colors
          .transparent, // Transparan agar bisa memodifikasi sudut melengkung
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.75, // Maksimal 75% tinggi layar
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis handle abu-abu di atas popup untuk indikator drag
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header Judul
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Detail Tugas",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Isi Detail (Bisa di-scroll jika panjang)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        Icons.assignment,
                        "Nama Tugas",
                        groupedTask.namaTugas,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.book,
                        "Mata Kuliah",
                        groupedTask.matkulNamaSaja,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.group,
                        "Target Kelas",
                        daftarKelasText.isEmpty
                            ? "Semua Kelas"
                            : daftarKelasText,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.access_time_filled,
                        "Deadline",
                        _formatDateTime(groupedTask.deadline),
                        iconColor: accentOrange,
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "Deskripsi",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          groupedTask.deskripsi ??
                              "Tidak ada deskripsi tambahan.",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),

                      // Jika ada lampiran, bisa ditampilkan di sini juga
                      if (representatifTask.lampiran != null &&
                          representatifTask.lampiran!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          "Lampiran",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...representatifTask.lampiran!.map(
                          (lamp) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              lamp['type'] == 'file'
                                  ? Icons.insert_drive_file
                                  : Icons.link,
                              color: secondaryBlue,
                            ),
                            title: Text(
                              lamp['title'] ?? 'Lampiran',
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              lamp['type'] == 'file' ? 'File' : 'Tautan Web',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget bantuan untuk merapikan baris detail
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor ?? secondaryBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
