import 'package:flutter/material.dart';

class ScheduleIndexPage extends StatelessWidget {
  const ScheduleIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            "Status Tracking Jadwal",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF4338CA),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF4338CA),
            tabs: [
              Tab(text: "Draft / Final"),
              Tab(text: "Published"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Navigasi ke CreatePage
          },
          backgroundColor: const Color(0xFF4338CA),
          icon: const Icon(Icons.add),
          label: const Text("Jadwal Baru"),
        ),
        body: const TabBarView(
          children: [
            _ScheduleList(statusType: "DRAFT"),
            _ScheduleList(statusType: "PUBLISHED"),
          ],
        ),
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  final String statusType;
  const _ScheduleList({required this.statusType});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Dummy
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Pemrograman Mobile",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    _buildStatusBadge(statusType),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Bapak Alfarizky, S.T., M.T.",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Senin, 08:00 - 10:30",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 4),
                    Text("GK-301", style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {}, // Edit
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Edit"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (statusType == "DRAFT")
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {}, // Finalisasi
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreenAccent,
                          ),
                          child: const Text("Finalisasi"),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == "PUBLISHED"
        ? Colors.lightGreenAccent
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
