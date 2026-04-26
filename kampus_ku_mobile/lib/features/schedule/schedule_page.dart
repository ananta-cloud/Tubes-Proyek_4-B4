import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kampus_ku_mobile/data/models/schedule_local_model.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jadwal Mengajar")),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ScheduleLocalModel>('schedules').listenable(),
        builder: (context, Box<ScheduleLocalModel> box, _) {
          final schedules = box.values.toList();
          return ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final s = schedules[index];
              return ListTile(
                title: Text(s.namaMk),
                subtitle: Text("${s.jamMulai} - ${s.jamSelesai} | ${s.ruangan}"),
                leading: const Icon(Icons.menu_book),
              );
            },
          );
        },
      ),
    );
  }
}