import 'package:flutter/material.dart';
import 'package:sigma/data/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  LoginViewModel(this._authRepo);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fungsi login mengembalikan objek user jika sukses, atau null jika gagal
  Future<dynamic> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authRepo.login(email, password);

      _isLoading = false;
      notifyListeners();

      return user;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  Future<void> logout() async {
    await _authRepo.logout();
  }
}
