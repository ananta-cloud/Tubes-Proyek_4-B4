import 'package:flutter/material.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/data/models/tpj_model.dart';
import 'requests/views/request_index_page.dart';
// import 'package:sigma/features/admin_tu/main/views/admin_main_page.dart';
import 'package:sigma/shared/widgets/page_header.dart';
import 'package:sigma/shared/app_colors.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';
import 'package:provider/provider.dart';
import 'package:sigma/features/penjadwalan/viewmodels/schedule_request_controller.dart';

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
    final ctrl = context.watch<ScheduleRequestController>();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          if (ctrl.isOffline)
            const Padding(padding: EdgeInsets.fromLTRB(12, 8, 12, 0)),
          PageHeader(
            title: 'Tim Penjadwalan',
            subtitle: widget.user.nama,
            action: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.navy),
              onPressed: () => _handleLogout(context),
            ),
          ),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Keluar"),
        content: const Text("Apakah Anda ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await context.read<LoginViewModel>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              "Keluar",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
