import 'package:flutter/material.dart';
import 'package:sigma/data/repositories/auth_repository.dart';
import 'package:sigma/data/models/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  LoginViewModel(this._authRepo);

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  dynamic _user;
  dynamic get user => _user;

  // Fungsi login mengembalikan objek user jika sukses, atau null jika gagal
  Future<dynamic> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

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

  Future<UserModel?> checkLogin() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authRepo.checkAutoLogin();
    if (result != null) {
      _user = result;
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