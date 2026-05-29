import 'task_model.dart';

class GroupedTask {
  final String baseId;
  final String namaTugas;
  final String? deskripsi;
  final String? kodeMk; // BERUBAH DARI idMk
  final String matkulNamaSaja;
  final List<String> targetKelasList;
  final DateTime deadline;
  final bool isSynced;
  final List<TaskModel> originalTasks;

  GroupedTask({
    required this.baseId,
    required this.namaTugas,
    this.deskripsi,
    this.kodeMk, // BERUBAH
    required this.matkulNamaSaja,
    required this.targetKelasList,
    required this.deadline,
    required this.isSynced,
    required this.originalTasks,
  });
}
