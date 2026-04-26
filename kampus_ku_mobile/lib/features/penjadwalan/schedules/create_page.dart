import 'package:flutter/material.dart';

class ScheduleCreatePage extends StatefulWidget {
  const ScheduleCreatePage({super.key});

  @override
  State<ScheduleCreatePage> createState() => _ScheduleCreatePageState();
}

class _ScheduleCreatePageState extends State<ScheduleCreatePage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedHari;
  String? selectedTipe = "KULIAH";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Input Jadwal Baru", style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlertCollision(), // Alert Error jika ada
              const SizedBox(height: 20),

              // Mata Kuliah Dropdown
              const Text(
                "MATA KULIAH *",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField(
                decoration: _inputStyle("Pilih Mata Kuliah"),
                items: const [
                  DropdownMenuItem(
                    value: "MK01",
                    child: Text("[IF22A] Basis Data"),
                  ),
                ],
                onChanged: (val) {},
              ),
              const SizedBox(height: 20),

              // Hari Dropdown
              const Text(
                "HARI *",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: _inputStyle("Pilih Hari"),
                value: selectedHari,
                items: ["Senin", "Selasa", "Rabu", "Kamis", "Jumat"]
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (val) => setState(() => selectedHari = val),
              ),
              const SizedBox(height: 20),

              // Jam Mulai & Selesai
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "JAM MULAI *",
                      "08:00",
                      suffixIcon: Icons.access_time,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      "JAM SELESAI *",
                      "10:30",
                      suffixIcon: Icons.access_time,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextField("RUANGAN *", "Cth: GK-301"),
              const SizedBox(height: 20),
              _buildTextField("NAMA DOSEN *", "Nama lengkap dosen"),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Logic simpan ke Laravel via API
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text(
                    "SIMPAN JADWAL",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper UI
  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildTextField(String label, String hint, {IconData? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: _inputStyle(hint).copyWith(
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCollision() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Bentrok Jadwal! Ruangan GK-301 sudah terpakai.",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
