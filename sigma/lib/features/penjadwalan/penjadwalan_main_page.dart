import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:sigma/core/network/mongo_database.dart';
import 'package:sigma/data/models/user_model.dart';
import 'package:sigma/data/models/tpj_model.dart';
import 'package:sigma/features/auth/viewmodels/login_viewmodel.dart';
import 'package:sigma/features/auth/views/login_page.dart';
import 'package:sigma/features/penjadwalan/viewmodels/schedule_request_controller.dart';
import 'package:sigma/shared/app_colors.dart';
import 'package:sigma/shared/widgets/page_header.dart';
import 'package:sigma/shared/widgets/offline_banner.dart';
import 'requests/views/request_index_page.dart';

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

  // StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  // bool _isSyncing = false;
  // bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _pages = [
      RequestsIndexPage(
        idJurusan: widget.timPenjadwalan.idJurusan,
        user: widget.user,
      ),
    ];

    Connectivity().checkConnectivity().then((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      MongoDatabase.isOffline = isOffline;
      if (mounted) {
        context.read<ScheduleRequestController>().setOffline(isOffline);
      }
    });

    // _initConnectivity();
  }

  // @override
  // void dispose() {
  //   _connectivitySub?.cancel();
  //   super.dispose();
  // }

  // void _initConnectivity() {
  //   // Cek status awal
  //   Connectivity().checkConnectivity().then((results) {
  //     final isOffline = results.contains(ConnectivityResult.none);
  //     MongoDatabase.isOffline = isOffline;
  //     if (mounted) {
  //       context.read<ScheduleRequestController>().setOffline(isOffline);
  //       _wasOffline = isOffline;
  //     }
  //   });

  //   // Listen perubahan
  //   _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
  //     final isOffline = results.contains(ConnectivityResult.none);
  //     MongoDatabase.isOffline = isOffline;

  //     if (!mounted) return;
  //     final ctrl = context.read<ScheduleRequestController>();
  //     ctrl.setOffline(isOffline);

  //     if (_wasOffline && !isOffline) {
  //       // Baru kembali online — sync
  //       _doSync(ctrl);
  //     }
  //     _wasOffline = isOffline;
  //   });
  // }

  // Future<void> _doSync(ScheduleRequestController ctrl) async {
  //   if (_isSyncing) return;
  //   setState(() => _isSyncing = true);

  //   try {
  //     await MongoDatabase.ensureConnected();
  //     await ctrl.onConnectionRestored();
  //   } finally {
  //     if (mounted) setState(() => _isSyncing = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScheduleRequestController>();

    // Snackbar sync berhasil
    if (ctrl.justSynced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Flexible(child: Text('Request berhasil tersinkronisasi')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        ctrl.clearSyncFlag();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          PageHeader(
            title: 'Tim Penjadwalan',
            subtitle: widget.user.nama,
            action: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.navy),
              onPressed: () => _handleLogout(context),
            ),
          ),

          // ── Offline banner / syncing indicator ──────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ctrl.isOffline
                ? const OfflineBanner(key: ValueKey('offline'))
                : ctrl.isSyncing
                ? _SyncingBanner(key: const ValueKey('syncing'))
                : const SizedBox.shrink(key: ValueKey('none')),
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
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
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
              'Keluar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Syncing Banner ─────────────────────────────────────────────────────────────
class _SyncingBanner extends StatelessWidget {
  const _SyncingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.navy.withValues(alpha: 0.08),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.navy,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Menyinkronkan data ke server...',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
