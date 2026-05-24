import 'package:flutter/material.dart';
import '../../../../data/models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';
import 'task_detail_page.dart';

class StudentTaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskViewModel viewModel;

  const StudentTaskCard({
    super.key,
    required this.task,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    bool isTerlambat = task.status == 'TERLAMBAT' ||
        (task.deadline.isBefore(DateTime.now()) && task.status == 'BELUM');

    String mkSnapshot = task.namaMkSnapshot ?? 'Umum';
    String initial = mkSnapshot.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
    if (initial.contains('-') || initial.length < 2) initial = "TG";

    String formattedDeadline = "${task.deadline.day}/${task.deadline.month}/${task.deadline.year} pukul ${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigasi langsung ke Detail Tugas saat di klik
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailPage(task: task),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: task.isPersonal ? Colors.teal.shade100 : Colors.blue.shade100,
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: task.isPersonal ? Colors.teal.shade800 : Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.namaTugas,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: task.status == 'SELESAI' ? Colors.grey : Colors.black87,
                            decoration: task.status == 'SELESAI' ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mkSnapshot,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: task.status == 'SELESAI',
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (bool? value) {
                        viewModel.toggleStatus(task);
                      },
                    ),
                  ),
                ],
              ),
              if (task.deskripsi != null && task.deskripsi!.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                Text(
                  task.deskripsi!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: task.status == 'SELESAI' ? Colors.grey : (isTerlambat ? Colors.red : Colors.orange.shade700),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Tenggat: $formattedDeadline",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: task.status == 'SELESAI' ? Colors.grey : (isTerlambat ? Colors.red : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (!task.isSynced)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.cloud_off, size: 14, color: Colors.grey),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: task.isPersonal ? Colors.teal.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.isPersonal ? "MANDIRI" : "DOSEN",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: task.isPersonal ? Colors.teal.shade700 : Colors.blue.shade700,
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
    );
  }
}