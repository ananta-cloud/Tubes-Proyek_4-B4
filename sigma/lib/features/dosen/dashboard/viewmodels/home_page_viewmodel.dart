import 'package:flutter/material.dart';

class DosenHomeViewModel extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // Logika ucapan selamat
  String get greeting {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi, Bapak/Ibu';
    if (hour < 17) return 'Selamat Siang, Bapak/Ibu';
    return 'Selamat Malam, Bapak/Ibu';
  }
}