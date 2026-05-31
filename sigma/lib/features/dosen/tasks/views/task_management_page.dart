import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box, State, Center, Size;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:async';

import '../../../../data/models/task_model.dart';
import '../../../../data/models/group_task_model.dart';
import '../../../../data/services/task_service.dart';
import '../../../auth/viewmodels/login_viewmodel.dart';
import '../../../../core/network/mongo_database.dart';
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

  final Map<String, String> _kelasCacheNames = {};
  late Box<TaskModel> _taskBox;
  final TaskService _taskService = TaskService();
  List<String> _selectedFilterMatkul = [];
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<TaskModel>('tasks');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDataFromServer();
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      bool isOnline = !(result as List).contains(ConnectivityResult.none);
      if (isOnline) {
        print("🌐 Jaringan kembali ONLINE! Memulai sinkronisasi otomatis...");
        _syncDataFromServer();
      }
    });
  }

  // 🔥 Ekstraktor ID universal yang anti-gagal agar data tidak terhapus
  String _extractId(String rawId) {
    final match = RegExp(r'[a-fA-F0-9]{24}').firstMatch(rawId);
    return match?.group(0) ?? rawId;
  }

  Future<String> _resolveNamaKelas(String idKelasHex) async {
    final cleanId = _extractId(idKelasHex);
    if (cleanId.length != 24) return cleanId;

    if (_kelasCacheNames.containsKey(cleanId))
      return _kelasCacheNames[cleanId]!;

    final cacheBox = Hive.box<String>('kelasCacheBox');
    if (cacheBox.containsKey(cleanId)) {
      String cachedName = cacheBox.get(cleanId)!;
      _kelasCacheNames[cleanId] = cachedName;
      return cachedName;
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOfflineNetwork = (connectivityResult as List).contains(
        ConnectivityResult.none,
      );

      if (isOfflineNetwork || MongoDatabase.isOffline) {
        return "Kelas (${cleanId.substring(0, 4)})";
      }

      final kelasDoc = await MongoDatabase.kelasCollection.findOne(
        where.id(ObjectId.parse(cleanId)),
      );

      if (kelasDoc != null && kelasDoc.containsKey('nama_kelas')) {
        String name = kelasDoc['nama_kelas'].toString();

        if (kelasDoc['id_prodi'] != null) {
          final dynamic rawProdiId = kelasDoc['id_prodi'];
          final ObjectId prodiObjId = rawProdiId is ObjectId
              ? rawProdiId
              : ObjectId.parse(_extractId(rawProdiId.toString()));
          final prodiDoc = await MongoDatabase.db
              .collection('prodi')
              .findOne(where.id(prodiObjId));

          if (prodiDoc != null && prodiDoc['nama_prodi'] != null) {
            String namaProdi = prodiDoc['nama_prodi'].toString().toUpperCase();
            if (namaProdi.contains('D3') || namaProdi.contains('D-III')) {
              name += "-D3";
            } else if (namaProdi.contains('D4') ||
                namaProdi.contains('D-IV') ||
                namaProdi.contains('SARJANA TERAPAN')) {
              name += "-D4";
            }
          }
        }

        _kelasCacheNames[cleanId] = name;
        await cacheBox.put(cleanId, name);

        return name;
      }
      return "Unknown";
    } catch (e) {
      debugPrint("Error resolve kelas: $e");
      return "Kelas (${cleanId.substring(0, 4)})";
    }
  }

  Future<List<GroupedTask>> dapatkanTugasTerkelompok(
    List<TaskModel> rawTasks,
  ) async {
    final Map<String, GroupedTask> groups = {};

    for (var task in rawTasks) {
      String matkulName = task.namaMkSnapshot ?? 'Umum';
      List<String> namaKelasTerkonversi = [];

      if (task.targetKelas != null && task.targetKelas!.isNotEmpty) {
        for (String idKelas in task.targetKelas!) {
          String resolvedName = await _resolveNamaKelas(idKelas);
          namaKelasTerkonversi.add(resolvedName);
        }
      }

      String timeKey =
          "${task.deadline.year}-${task.deadline.month}-${task.deadline.day}_${task.deadline.hour}:${task.deadline.minute}";
      String key = "${task.kodeMk}_${timeKey}_${task.namaTugas}";

      if (groups.containsKey(key)) {
        for (String nKelas in namaKelasTerkonversi) {
          if (nKelas.isNotEmpty &&
              !groups[key]!.targetKelasList.contains(nKelas)) {
            groups[key]!.targetKelasList.add(nKelas);
          }
        }
        groups[key]!.originalTasks.add(task);
      } else {
        groups[key] = GroupedTask(
          baseId: task.id,
          namaTugas: task.namaTugas,
          deskripsi: task.deskripsi,
          kodeMk: task.kodeMk,
          matkulNamaSaja: matkulName,
          targetKelasList: namaKelasTerkonversi,
          deadline: task.deadline,
          isSynced: task.isSynced,
          originalTasks: [task],
        );
      }
    }

    final groupedList = groups.values.toList();
    groupedList.sort((a, b) => a.deadline.compareTo(b.deadline));
    return groupedList;
  }

  Set<String> get _allMataKuliah {
    final user = context.read<LoginViewModel>().user;
    if (user == null || user.role.toUpperCase() != 'DOSEN') return {};

    final String cleanUserId = _extractId(user.id);
    final matkulSet = <String>{};

    for (final task in _taskBox.values) {
      if (_extractId(task.idUser) == cleanUserId &&
          task.namaMkSnapshot != null) {
        String snapshot = task.namaMkSnapshot!;
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
    final String cleanId = _extractId(userId);

    return _taskBox.values.where((task) {
      if (_extractId(task.idUser) != cleanId) return false;
      if (_selectedFilterMatkul.isNotEmpty) {
        if (task.namaMkSnapshot == null) return false;
        bool matches = false;
        for (String matkul in _selectedFilterMatkul) {
          if (task.namaMkSnapshot!.contains(matkul)) {
            matches = true;
            break;
          }
        }
        return matches;
      }
      return true;
    }).toList();
  }

  Future<void> _syncDataFromServer() async {
    try {
      final user = context.read<LoginViewModel>().user;
      if (user == null) return;

      String cleanId = _extractId(user.id);

      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOffline = (connectivityResult as List).contains(
        ConnectivityResult.none,
      );
      if (isOffline) return;

      if (MongoDatabase.isOffline) {
        await MongoDatabase.connect();
      }

      List<Map<String, dynamic>> rawCloudTasks = await _taskService
          .getTasksByUser(cleanId);
      List<TaskModel> cloudTasks = [];

      for (var data in rawCloudTasks) {
        try {
          if (data['_id'] != null)
            data['_id'] = _extractId(data['_id'].toString());
          if (data['id_user'] != null)
            data['id_user'] = _extractId(data['id_user'].toString());

          final t = TaskModel.fromMongo(data);
          t.isSynced = true;
          cloudTasks.add(t);
        } catch (e) {
          print("⚠️ Error parsing TaskModel: $e");
        }
      }

      Set<String> cloudIds = cloudTasks.map((t) => t.id).toSet();
      final pendingTasks = _taskBox.values.where((t) => !t.isSynced).toList();
      bool hasNewUploads = false;

      if (pendingTasks.isNotEmpty) {
        await Future.wait(
          pendingTasks.map((task) async {
            bool success = false;
            final taskHexId = _extractId(task.id);
            if (cloudIds.contains(taskHexId)) {
              success = await _taskService.updateTask(task);
            } else {
              success = await _taskService.createTask(task);
            }

            if (success) {
              task.isSynced = true;
              await _taskBox.put(task.id, task);
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
            if (data['_id'] != null)
              data['_id'] = _extractId(data['_id'].toString());
            if (data['id_user'] != null)
              data['id_user'] = _extractId(data['id_user'].toString());

            final t = TaskModel.fromMongo(data);
            t.isSynced = true;
            cloudTasks.add(t);
            cloudIds.add(t.id);
          } catch (_) {}
        }
      }

      final Map<String, TaskModel> tasksToPut = {};
      final List<String> keysToDelete = [];

      for (var taskFromServer in cloudTasks) {
        final localTask = _taskBox.get(taskFromServer.id);
        if (localTask == null || localTask.isSynced == true) {
          tasksToPut[taskFromServer.id] = taskFromServer;
        }
      }

      final localKeys = _taskBox.keys.cast<String>().toList();
      for (var key in localKeys) {
        final taskInHive = _taskBox.get(key);
        if (taskInHive != null &&
            taskInHive.isSynced &&
            !cloudIds.contains(_extractId(key))) {
          keysToDelete.add(key);
        }
      }

      if (rawCloudTasks.isNotEmpty && cloudTasks.isEmpty) {
        print(
          "⚠️ Parsing data dari Server gagal. Membatalkan penghapusan data lokal.",
        );
      } else {
        if (tasksToPut.isNotEmpty) await _taskBox.putAll(tasksToPut);
        if (keysToDelete.isNotEmpty) await _taskBox.deleteAll(keysToDelete);
      }

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
          final allMatkul = _allMataKuliah.toList()..sort();

          return Column(
            children: [
              if (allMatkul.isNotEmpty) _buildFilterBar(allMatkul),
              Expanded(
                child: FutureBuilder<List<GroupedTask>>(
                  future: dapatkanTugasTerkelompok(rawTasks),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: secondaryBlue),
                      );
                    }
                    final groupedTasks = snapshot.data ?? [];

                    return RefreshIndicator(
                      onRefresh: _syncDataFromServer,
                      color: secondaryBlue,
                      backgroundColor: Colors.white,
                      child: groupedTasks.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: _buildEmptyState(),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: groupedTasks.length,
                              itemBuilder: (context, index) {
                                return _buildGroupedTaskCard(
                                  groupedTasks[index],
                                );
                              },
                            ),
                    );
                  },
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
    List<String> selectedMatkuls = [];
    List<String> unselectedMatkuls = [];
    for (String m in matkulList) {
      if (_selectedFilterMatkul.contains(m))
        selectedMatkuls.add(m);
      else
        unselectedMatkuls.add(m);
    }
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  'Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _selectedFilterMatkul.isEmpty
                        ? Colors.white
                        : secondaryBlue,
                  ),
                ),
                selected: _selectedFilterMatkul.isEmpty,
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
                  onSelected: (_) => setState(() {
                    isSelected
                        ? _selectedFilterMatkul.remove(matkul)
                        : _selectedFilterMatkul.add(matkul);
                  }),
                  backgroundColor: Colors.white,
                  selectedColor: secondaryBlue,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected ? secondaryBlue : Colors.grey.shade300,
                  ),
                ),
              );
            }),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTaskDetailBottomSheet(context, groupedTask),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: secondaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: secondaryBlue.withOpacity(0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          groupedTask.namaTugas,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: secondaryBlue,
                            height: 1.3,
                          ),
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusChip(representatifTask.status),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 16,
                        color: secondaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: "${groupedTask.matkulNamaSaja} ",
                            style: const TextStyle(
                              fontSize: 13,
                              color: primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    "(${daftarKelasText.isEmpty ? 'Semua Kelas' : daftarKelasText})",
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Deadline: ${_formatDateTime(groupedTask.deadline)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (representatifTask.lampiran != null &&
                        representatifTask.lampiran!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.attach_file_rounded,
                        size: 15,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${representatifTask.lampiran!.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          groupedTask.isSynced
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_upload_rounded,
                          size: 16,
                          color: groupedTask.isSynced
                              ? Colors.green.shade600
                              : accentOrange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          groupedTask.isSynced
                              ? "Tersinkronisasi"
                              : "Menunggu Jaringan",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: groupedTask.isSynced
                                ? Colors.green.shade700
                                : accentOrange,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _navigateToEditTask(representatifTask),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: secondaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: secondaryBlue,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: secondaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _deleteGroupedTask(groupedTask),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Hapus',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: secondaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: secondaryBlue.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Nama Tugas",
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              groupedTask.namaTugas,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: secondaryBlue,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                        ...representatifTask.lampiran!.map((lamp) {
                          final fileName =
                              lamp['title'] ?? lamp['name'] ?? 'Lampiran';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            // 🔥 LOGIKA PREVIEW LAMPIRAN
                            onTap: () async {
                              String dataBase64 =
                                  lamp['data']?.toString() ?? '';
                              String uriString = lamp['uri']?.toString() ?? '';

                              // ==========================================================
                              // SKENARIO 1: FILE CLOUD (BASE 64)
                              // ==========================================================
                              if (dataBase64.isNotEmpty &&
                                  dataBase64 != 'null') {
                                try {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Mengunduh & Membuka file dari cloud...",
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );

                                  final bytes = base64Decode(dataBase64);
                                  final tempDir = await getTemporaryDirectory();
                                  final tempFile = File(
                                    '${tempDir.path}/$fileName',
                                  );
                                  await tempFile.writeAsBytes(bytes);

                                  final result = await OpenFilex.open(
                                    tempFile.path,
                                  );
                                  if (result.type != ResultType.done) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Gagal membuka file: ${result.message}",
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                } catch (e) {
                                  debugPrint("Error decode Base64: $e");
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "⚠️ File rusak atau tidak valid.",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                              // ==========================================================
                              // SKENARIO 2: FILE LOKAL (DRAFT)
                              // ==========================================================
                              else if (uriString.isNotEmpty &&
                                  uriString != 'null') {
                                final file = File(uriString);
                                if (await file.exists()) {
                                  try {
                                    final result = await OpenFilex.open(
                                      uriString,
                                    );
                                    if (result.type != ResultType.done) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Gagal membuka file: ${result.message}",
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint("Error membuka file: $e");
                                  }
                                } else {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "⚠️ File draf lokal tidak ditemukan (cache HP dibersihkan).",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("⚠️ Data lampiran kosong."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: secondaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                lamp['type'] == 'file'
                                    ? Icons.insert_drive_file
                                    : Icons.link,
                                color: secondaryBlue,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              lamp['type'] == 'file'
                                  ? 'Ketuk untuk melihat file'
                                  : 'Tautan Web',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 40),
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

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
