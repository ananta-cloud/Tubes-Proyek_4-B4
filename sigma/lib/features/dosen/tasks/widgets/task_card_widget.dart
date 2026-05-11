import 'package:flutter/material.dart';
import 'package:sigma/data/models/task_model.dart';

class TaskCardWidget extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          task.namaTugas,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(
              "📍 Kelas: ${task.namaMkSnapshot ?? 'Umum'}", // Di sini tampilkan info kelas
              style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
            ),
            Text(
              "⏰ Deadline: ${task.deadline.toString().substring(0, 16)}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indikator Cloud (Penting untuk Offline-First)
            Icon(
              task.isSynced ? Icons.cloud_done : Icons.cloud_off,
              size: 18,
              color: task.isSynced ? Colors.green : Colors.orange,
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
