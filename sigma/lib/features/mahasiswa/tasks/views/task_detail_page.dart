import 'package:flutter/material.dart';
import '../../../../data/models/task_model.dart';

class TaskDetailPage extends StatelessWidget {
  final TaskModel task;

  const TaskDetailPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    String formattedDeadline = "${task.deadline.day}/${task.deadline.month}/${task.deadline.year} pukul ${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Instruksi Tugas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.namaMkSnapshot ?? 'Mata Kuliah Umum',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              task.namaTugas,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Text(
                  "Batas Pengumpulan: $formattedDeadline",
                  style: TextStyle(fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            const Text(
              "Deskripsi Instruksi:",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                task.deskripsi != null && task.deskripsi!.isNotEmpty
                    ? task.deskripsi!
                    : 'Tidak ada deskripsi atau instruksi tambahan dari Dosen untuk tugas ini.',
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}