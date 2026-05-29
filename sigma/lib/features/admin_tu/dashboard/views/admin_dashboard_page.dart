import 'package:flutter/material.dart';
// import 'package:sigma/shared/widgets/empty_state.dart';
// import 'package:sigma/shared/widgets/page_header.dart';
// import 'package:sigma/shared/widgets/primary_button.dart';
import 'package:sigma/shared/widgets/stat_card.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Admin TU"),
        backgroundColor: const Color(0xFF3F5DB3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StatCard(label: "Jadwal Draft", value: 0, accent: Colors.orange),
            const SizedBox(height: 12),
            StatCard(label: "Jadwal Published", value: 0, accent: Colors.green),
            const SizedBox(height: 12),
            StatCard(label: "Total Jadwal", value: 0, accent: Colors.blue),
          ],
        ),
      ),
    );
  }

  // Widget _card(String title, int value, Color color) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(0.15),
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(title, style: const TextStyle(fontSize: 16)),
  //         Text(
  //           value.toString(),
  //           style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
