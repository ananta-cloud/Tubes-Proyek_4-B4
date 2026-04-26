import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class CreateRevisiSheet extends StatefulWidget {
  const CreateRevisiSheet({super.key});

  @override
  State<CreateRevisiSheet> createState() => _CreateRevisiSheetState();
}

class _CreateRevisiSheetState extends State<CreateRevisiSheet> {
  String scope = "SEMESTER";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Buat Periode Baru",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 15),

          _label("Judul Periode"),
          _textField("Cth: Revisi Genap 2026"),

          const SizedBox(height: 15),
          _label("Scope"),
          DropdownButtonFormField<String>(
            value: scope,
            decoration: _inputDecoration(),
            items: const [
              DropdownMenuItem(
                value: "SEMESTER",
                child: Text("SEMESTER - Semua Dosen"),
              ),
              DropdownMenuItem(
                value: "MATKUL",
                child: Text("MATKUL - Satu MK"),
              ),
            ],
            onChanged: (val) => setState(() => scope = val!),
          ),

          if (scope == "MATKUL") ...[
            const SizedBox(height: 15),
            _label("Mata Kuliah"),
            DropdownButtonFormField(
              decoration: _inputDecoration(),
              items: const [
                DropdownMenuItem(
                  value: "1",
                  child: Text("Matematika - Pak Nazriel"),
                ),
              ],
              onChanged: (val) {},
            ),
          ],

          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Mulai"),
                    _textField("YYYY-MM-DD", icon: Icons.calendar_today),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Selesai"),
                    _textField("YYYY-MM-DD", icon: Icons.calendar_today),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4338CA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "SIMPAN PERIODE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.slate700,
      ),
    ),
  );

  Widget _textField(String hint, {IconData? icon}) => TextFormField(
    decoration: _inputDecoration().copyWith(
      hintText: hint,
      suffixIcon: icon != null ? Icon(icon, size: 18) : null,
    ),
  );

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}
