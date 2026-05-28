import 'package:flutter/material.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/data/models/tpj_model.dart';
import 'requests/views/request_index_page.dart';
import 'package:sigma/features/admin_tu/main/views/admin_main_page.dart';

class PenjadwalanMainPage extends StatefulWidget {
  final UserModel user;
  final TimPenjadwalanModel timPenjadwalan;
  const PenjadwalanMainPage({
    super.key,
    required this.user,
    required this.timPenjadwalan,
  });

  @override
  State<PenjadwalanMainPage> createState() => _PenjadwalanMainPageState();
}

class _PenjadwalanMainPageState extends State<PenjadwalanMainPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      RequestsIndexPage(
        idJurusan: widget.timPenjadwalan.idJurusan,
        user: widget.user,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SigmaColors.bgPage,
      body: Column(
        children: [
          SigmaPageHeader(title: 'Tim Penjadwalan', subtitle: widget.user.nama),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
    );
  }
}
