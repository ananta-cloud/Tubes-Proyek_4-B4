import 'package:flutter/material.dart';
import 'package:sigma/data/repositories/auth_repository.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/data/models/dosen_model.dart';
import 'package:sigma/data/models/tpj_model.dart';
import 'package:sigma/data/services/notification_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  LoginViewModel(this._authRepo);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _user;
  UserModel? get user => _user;

  DosenModel? _dosen;
  DosenModel? get dosen => _dosen;

  TimPenjadwalanModel? _timPenjadwalan;
  TimPenjadwalanModel? get timPenjadwalan => _timPenjadwalan;

  Future<UserModel?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final result = await _authRepo.login(email, password);
      _user = result;

      if (result != null) {
        NotificationService.subscribeToRole(result.role).catchError((e) {
          debugPrint("FCM Subscribe gagal (diabaikan): $e");
        });

        if (result.isDosen) {
          _dosen = await _authRepo.getDosenByUserId(result.id);

          if (_dosen != null) {
            _user = UserModel(
              id: result.id,
              nama: _dosen!.namaDosen,
              email: result.email,
              role: result.role,
              deviceToken: result.deviceToken,
              profilMahasiswa: result.profilMahasiswa,
            );
          }
        }
        if (result.isTimPenjadwalan) {
          _timPenjadwalan = await _authRepo.getTimPenjadwalanByUserId(
            result.id,
          );
          if (_timPenjadwalan != null) {
            _user = UserModel(
              id: result.id,
              nama: _timPenjadwalan!.nama,
              email: result.email,
              role: result.role,
              deviceToken: result.deviceToken,
              profilMahasiswa: result.profilMahasiswa,
            );
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return _user;
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

      if (result.isDosen) {
        _dosen = await _authRepo.getDosenByUserId(result.id);
      }

      if (result.isTimPenjadwalan) {
        _timPenjadwalan = await _authRepo.getTimPenjadwalanByUserId(result.id);
      }
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await _authRepo.logout();
    _user = null;
    _dosen = null;
    _timPenjadwalan = null;
    notifyListeners();
  }
}
