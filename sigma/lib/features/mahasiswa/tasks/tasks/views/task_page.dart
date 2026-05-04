import 'package:flutter/material.dart';
import '../viewmodels/task_viewmodel.dart';
import '../../../../../data/models/task_model.dart';

class TaskPage extends StatefulWidget {
  final TaskViewModel controller;
  final TaskModel? taskToEdit; // Jika null = Tambah Baru, Jika terisi = Edit

  const TaskPage({super.key, required this.controller, this.taskToEdit});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  // Warna Tema SIGMA
  static const primaryBlue = Color(0xFF1F1F3D);
  static const secondaryBlue = Color(0xFF3F5DB3);
  static const accentOrange = Color(0xFFFF7A36);
  static const bgColor = Color(0xFFEAF3FA);

  final _namaTugasController = TextEditingController();
  String? _selectedMatkul;
  DateTime? _selectedDeadline;

  final List<String> _matkulList = [
    'Rekayasa Perangkat Lunak', 'Basis Data', 'Pemrograman Mobile', 'Jaringan Komputer'
  ];

  @override
  void initState() {
    super.initState();
    // Jika dalam Mode Edit, isi form dengan data tugas sebelumnya
    if (widget.taskToEdit != null) {
      _namaTugasController.text = widget.taskToEdit!.namaTugas;
      _selectedMatkul = widget.taskToEdit!.namaMkSnapshot;
      _selectedDeadline = widget.taskToEdit!.deadline;
      
      // Validasi agar matkul dummy tidak error jika beda
      if (_selectedMatkul != null && !_matkulList.contains(_selectedMatkul)) {
        _matkulList.add(_selectedMatkul!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditMode = widget.taskToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? "Edit Tugas" : "Tambah Tugas Baru", 
          style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          if (isEditMode) // Tombol Hapus hanya muncul di mode Edit
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                widget.controller.deleteTask(widget.taskToEdit!);
                Navigator.pop(context); // Kembali ke Home setelah dihapus
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _namaTugasController,
              decoration: InputDecoration(
                labelText: "Nama Tugas",
                prefixIcon: const Icon(Icons.edit_document, color: secondaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedMatkul,
              decoration: InputDecoration(
                labelText: "Mata Kuliah",
                prefixIcon: const Icon(Icons.menu_book, color: secondaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _matkulList.map((matkul) {
                return DropdownMenuItem<String>(value: matkul, child: Text(matkul));
              }).toList(),
              onChanged: (val) => setState(() => _selectedMatkul = val),
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDeadline ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)), // Izinkan pilih hari lampau
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDeadline ?? DateTime.now()),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  }
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Waktu Deadline",
                  prefixIcon: const Icon(Icons.access_time_filled, color: accentOrange),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _selectedDeadline != null 
                    ? "${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year} - ${_selectedDeadline!.hour.toString().padLeft(2, '0')}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}"
                    : "Pilih Tanggal & Waktu",
                  style: TextStyle(color: _selectedDeadline != null ? primaryBlue : Colors.grey.shade600, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_namaTugasController.text.isNotEmpty && _selectedDeadline != null) {
                if (isEditMode) {
                  widget.controller.updateTask(
                    task: widget.taskToEdit!,
                    nama: _namaTugasController.text, 
                    matkul: _selectedMatkul, 
                    deadline: _selectedDeadline!
                  );
                } else {
                  widget.controller.addTask(
                    nama: _namaTugasController.text, 
                    matkul: _selectedMatkul, 
                    deadline: _selectedDeadline!
                  );
                }
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama Tugas & Deadline wajib diisi!")));
              }
            },
            child: Text(
              isEditMode ? "Simpan Perubahan" : "Simpan Tugas Baru", 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
            ),
          ),
        ),
      ),
    );
  }
}