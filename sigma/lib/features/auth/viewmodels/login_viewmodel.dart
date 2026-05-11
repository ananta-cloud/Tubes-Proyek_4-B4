import 'package:flutter/material.dart';
import 'package:sigma/data/repositories/auth_repository.dart';
import 'package:sigma/data/models/user_model.dart'; // Tambahkan import UserModel Anda

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  LoginViewModel(this._authRepo);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Ganti dynamic menjadi UserModel? agar lebih aman dan auto-complete berfungsi di UI
  UserModel? _user;
  UserModel? get user => _user;

  // Fungsi login mengembalikan objek user jika sukses, atau null jika gagal
  Future<UserModel?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Trik Wajib: Beri jeda 100ms agar UI sempat menggambar indikator loading
    // sebelum HP bekerja keras menyambungkan diri ke MongoDB Atlas
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final result = await _authRepo.login(email, password);

      // Simpan hasil login ke dalam state _user
      _user = result;

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();

    // Hapus data user dari state saat logout
    _user = null;
    notifyListeners();
  }

  Future<bool> checkLogin() async {
    _isLoading = true;
    notifyListeners();

    // Coba tarik data dari storage
    final savedUser = await _authRepo.checkLoginStatus();

    if (savedUser != null) {
      _user = savedUser; // Set user aktif
      _isLoading = false;
      notifyListeners();
      return true; // Berarti ada user yang tersimpan (Sudah login)
    }

    _isLoading = false;
    notifyListeners();
    return false; // Berarti belum login / data kosong
  }
}