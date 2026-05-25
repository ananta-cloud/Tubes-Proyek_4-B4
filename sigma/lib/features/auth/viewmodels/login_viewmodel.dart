import 'package:flutter/material.dart';
import 'package:sigma/data/repositories/auth_repository.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/data/services/notification_service.dart';

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

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final result = await _authRepo.login(email, password);

      // Simpan hasil login ke dalam state _user
      _user = result;

      if (result != null) {
        NotificationService.subscribeToRole(result.role).catchError((e) {
          debugPrint("FCM Subscribe gagal (diabaikan): $e");
        });
      }

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<UserModel?> checkLogin() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authRepo.checkAutoLogin();
    if (result != null) {
      _user = result;
      NotificationService.subscribeToRole(result.role).catchError((e) {
        debugPrint("FCM Tertunda karena offline: $e");
      });
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await _authRepo.logout();

    // Hapus data user dari state saat logout
    _user = null;
    notifyListeners();
  }
}
