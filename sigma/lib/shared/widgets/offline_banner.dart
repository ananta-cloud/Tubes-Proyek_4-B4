import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final String? message;
  const OfflineBanner({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? 'Mode Offline — perubahan akan disinkronkan otomatis',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
