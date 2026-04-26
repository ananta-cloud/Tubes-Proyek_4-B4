import 'package:flutter/material.dart';
// Import model jadwal kamu, anggaplah namanya ScheduleModel
import 'package:kampus_ku_mobile/features/schedule/data/models/schedule_local_model.dart';

class ScheduleEditPage extends StatefulWidget {
  // Kita terima data jadwal yang mau diedit dari halaman Index
  final Map<String, dynamic> scheduleData;

  const ScheduleEditPage({super.key, required this.scheduleData});

  @override
  State<ScheduleEditPage> createState() => _ScheduleEditPageState();
}

class _ScheduleEditPageState extends State<ScheduleEditPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk mengisi text field dengan data lama
  late TextEditingController _ruanganController;
  late TextEditingController _dosenController;
  late TextEditingController _jamMulaiController;
  late TextEditingController _jamSelesaiController;

  String? selectedHari;
  String? selectedTipe;

  @override
  void initState() {
    super.initState();
    // Isi controller dengan data yang dikirim dari constructor (data lama)
    // Sesuai dengan value="{{ old('ruangan', $jadwal->ruangan) }}" di Laravel
    _ruanganController = TextEditingController(
      text: widget.scheduleData['ruangan'],
    );
    _dosenController = TextEditingController(
      text: widget.scheduleData['nama_dosen'],
    );
    _jamMulaiController = TextEditingController(
      text: widget.scheduleData['jam_mulai'],
    );
    _jamSelesaiController = TextEditingController(
      text: widget.scheduleData['jam_selesai'],
    );

    selectedHari = widget.scheduleData['hari'];
    selectedTipe = widget.scheduleData['tipe'];
  }

  @override
  void dispose() {
    // Jangan lupa dispose agar tidak memory leak
    _ruanganController.dispose();
    _dosenController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Jadwal", style: TextStyle(fontSize: 16)),
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
              // 1. INFO ALERT (Perhatian Edit mereset ke DRAFT)
              _buildEditWarningAlert(),
              const SizedBox(height: 20),

              // 2. READ-ONLY INFO MATKUL (Sama seperti di blade)
              _buildReadOnlyMatkulInfo(),
              const SizedBox(height: 24),

              const Divider(),
              const SizedBox(height: 20),

              // 3. FORM EDITABLE (Sama seperti Create)

              // Tipe Ujian (Radio di Laravel, kita pakai Dropdown/Segmented buat Mobile biar rapi)
              const Text(
                "TIPE JADWAL *",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: _inputStyle("Pilih Tipe"),
                value: selectedTipe,
                items: const [
                  DropdownMenuItem(value: "KULIAH", child: Text("Perkuliahan")),
                  DropdownMenuItem(value: "UTS", child: Text("UTS")),
                  DropdownMenuItem(value: "UAS", child: Text("UAS")),
                ],
                onChanged: (val) => setState(() => selectedTipe = val),
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
                items: ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"]
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (val) => setState(() => selectedHari = val),
              ),
              const SizedBox(height: 20),

              // Jam
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "JAM MULAI *",
                      "08:00",
                      controller: _jamMulaiController,
                      suffixIcon: Icons.access_time,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      "JAM SELESAI *",
                      "10:30",
                      controller: _jamSelesaiController,
                      suffixIcon: Icons.access_time,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextField(
                "RUANGAN *",
                "Cth: GK-301",
                controller: _ruanganController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                "NAMA DOSEN *",
                "Nama dosen",
                controller: _dosenController,
              ),

              const SizedBox(height: 30),

              // BUTTON SUBMIT (Sesuai dengan `method('PUT')` di Laravel)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Logic UPDATE ke Laravel via API (kirim PUT request)
                      // Pastikan menyertakan ID Jadwal: widget.scheduleData['id']
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    "SIMPAN PERUBAHAN",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA), // Indigo
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER UI ---

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

  Widget _buildTextField(
    String label,
    String hint, {
    required TextEditingController controller,
    IconData? suffixIcon,
  }) {
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
          controller: controller,
          decoration: _inputStyle(hint).copyWith(
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18) : null,
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildReadOnlyMatkulInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // grey 100
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)), // grey 200
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MATA KULIAH (Tidak dapat diubah)",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.scheduleData['nama_mk'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            "${widget.scheduleData['kode_mk']} • ${widget.scheduleData['id_periode']}",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEditWarningAlert() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Perhatian",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ), // Amber 900
                SizedBox(height: 2),
                Text(
                  "Perubahan akan mereset status ke DRAFT dan diperiksa collision-nya kembali.",
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 12,
                  ), // Amber 700
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
