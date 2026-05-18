import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../data/models/task_model.dart';
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
  String? _selectedFilterMatkul;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<TaskModel>('tasks');
    _syncDataFromServer();
  }

  List<TaskModel> get _myTasks {
    // 1. Ambil ID mentah dari ViewModel
    final rawUserId = context.read<LoginViewModel>().user?.id ?? '';
    
    // 2. BERSIHKAN ID DARI FORMAT OBJECTID (SANGAT PENTING)
    final cleanUserId = rawUserId.replaceAll('ObjectId("', '').replaceAll('")', '');

    print('🔍 [TaskManagement] Raw UserId: $rawUserId');
    print('🔍 [TaskManagement] Clean UserId: $cleanUserId');
    print('🔍 [TaskManagement] Total tasks in box: ${_taskBox.length}');

    // 3. Filter berdasarkan ID yang sudah bersih
    final filteredTasks = _taskBox.values.where((task) {
      // Pastikan task.idUser juga bersih dari ObjectId jika kebetulan kotor
      final cleanTaskId = task.idUser.replaceAll('ObjectId("', '').replaceAll('")', '');
      
      return cleanTaskId == cleanUserId;
    }).toList();

    print('✅ [TaskManagement] Filtered tasks: ${filteredTasks.length}');
    
    return filteredTasks;
  }

  Set<String> get _allMataKuliah {
    final userId = context.read<LoginViewModel>().user?.id ?? '';
    final matkulSet = <String>{};
    for (final task in _taskBox.values.where((task) => task.idUser == userId)) {
      if (task.namaMkSnapshot != null && task.namaMkSnapshot!.isNotEmpty) {
        matkulSet.add(task.namaMkSnapshot!);
      }
    }
    return matkulSet;
  }

  List<MapEntry<String, List<TaskModel>>> get _taskGroups {
    final groups = <String, List<TaskModel>>{};
    for (final task in _myTasks) {
      final groupKey = (task.namaMkSnapshot?.trim().isNotEmpty == true)
          ? task.namaMkSnapshot!.trim()
          : 'Umum';
      groups.putIfAbsent(groupKey, () => []).add(task);
    }

    final sortedGroups = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final group in sortedGroups) {
      group.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return sortedGroups;
  }

  void _navigateToCreateTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormPage()),
    ).then((_) {
      print('🔄 [TaskManagement] Returning from form, refreshing...');
      setState(() {});
    });
  }

  void _navigateToEditTask(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormPage(taskToEdit: task)),
    ).then((_) {
      print('🔄 [TaskManagement] Returning from edit, refreshing...');
      setState(() {});
    });
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: const Text('Apakah Anda yakin ingin menghapus tugas ini?'),
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
      await _taskBox.delete(task.id);

      // Also delete from MongoDB if online
      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOffline = (connectivityResult as List).contains(
        ConnectivityResult.none,
      );

      if (!isOffline) {
        await _taskService.deleteTask(task.id);
      }

      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tugas berhasil dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Pantau perubahan box secara real-time
      body: ValueListenableBuilder<Box<TaskModel>>(
        valueListenable: _taskBox.listenable(),
        builder: (context, box, _) {
          // Getter _myTasks sekarang akan mendeteksi data baru yang masuk dari sync
          final tasks = _myTasks; 
          final groups = _taskGroups;
          final allMatkul = _allMataKuliah.toList()..sort();

          return Column(
            children: [
              if (allMatkul.isNotEmpty) _buildFilterBar(allMatkul),
              Expanded(
                child: tasks.isEmpty 
                    ? _buildEmptyState() 
                    : _buildTaskList(groups),
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
            if (_selectedFilterMatkul != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Semua', style: TextStyle(fontSize: 13)),
                  onSelected: (_) =>
                      setState(() => _selectedFilterMatkul = null),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: secondaryBlue),
                ),
              ),
            ...matkulList.map((matkul) {
              final isSelected = _selectedFilterMatkul == matkul;
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
                  onSelected: (_) => setState(
                    () => _selectedFilterMatkul = isSelected ? null : matkul,
                  ),
                  backgroundColor: isSelected ? secondaryBlue : Colors.white,
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreateTask,
            icon: const Icon(Icons.add),
            label: const Text('Buat Tugas Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<MapEntry<String, List<TaskModel>>> groups) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader(group.key, group.value.length),
            const SizedBox(height: 8),
            ...group.value.map(_buildTaskCard).toList(),
            if (index != groups.length - 1) const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildGroupHeader(String groupName, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count tugas',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToEditTask(task),
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
                      task.namaTugas,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  _buildStatusChip(task.status),
                ],
              ),
              if (task.namaMkSnapshot != null &&
                  task.namaMkSnapshot!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.namaMkSnapshot!,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${_formatDateTime(task.deadline)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (task.lampiran != null && task.lampiran!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${task.lampiran!.length} lampiran',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0, // Menggantikan fungsi SizedBox(width: 8)
                runSpacing:
                    4.0, // Jarak vertikal jika elemen turun ke baris bawah
                alignment: WrapAlignment.end, // Agar tombol merapat ke kanan
                children: [
                  TextButton.icon(
                    onPressed: () => _navigateToEditTask(task),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: secondaryBlue),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteTask(task),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Hapus'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncDataFromServer() async {
    try {
      final user = context.read<LoginViewModel>().user;
      if (user == null) return;

      // Pastikan ID bersih tanpa string "ObjectId"
      String cleanId = user.id
          .replaceAll('ObjectId("', '')
          .replaceAll('")', '');

      // Cek Koneksi
      final connectivityResult = await Connectivity().checkConnectivity();
      if ((connectivityResult as List).contains(ConnectivityResult.none))
        return;

      // Panggil Service untuk ambil data dari MongoDB
      // (Pastikan fungsi getTasksByUser sudah ada di TaskService Anda)
      final List<Map<String, dynamic>> cloudTasks = await _taskService
          .getTasksByUser(cleanId);

      // Simpan data dari Cloud ke lokal Hive
      for (var data in cloudTasks) {
        final task = TaskModel.fromMongo(data);
        await _taskBox.put(task.id, task);
      }

      if (mounted) setState(() {}); // Segarkan layar setelah data masuk
    } catch (e) {
      print("❌ Gagal Sinkronisasi: $e");
    }
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
