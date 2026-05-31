import 'package:flutter/material.dart';

enum AdminMenu { kelolaJadwal, pengumuman, masterMatkul }

class AdminMainViewModel extends ChangeNotifier {
  AdminMenu _selectedMenu = AdminMenu.kelolaJadwal;

  AdminMenu get selectedMenu => _selectedMenu;

  void selectMenu(AdminMenu menu) {
    if (_selectedMenu != menu) {
      _selectedMenu = menu;
      notifyListeners();
    }
  }

  int get selectedIndex => AdminMenu.values.indexOf(_selectedMenu);

  void selectIndex(int index) {
    selectMenu(AdminMenu.values[index]);
  }
}
