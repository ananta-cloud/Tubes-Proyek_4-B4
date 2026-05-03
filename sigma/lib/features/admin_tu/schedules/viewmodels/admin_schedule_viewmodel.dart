import 'package:flutter/material.dart';

import '../../../../../core/network/mongo_database.dart';
import '../models/schedule_model.dart';

class AdminScheduleViewModel extends ChangeNotifier {
  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  int get draftCount =>
      _schedules.where((s) => s.status.toUpperCase() == 'DRAFT').length;
  int get publishedCount =>
      _schedules.where((s) => s.status.toUpperCase() == 'PUBLISHED').length;

  Future<void> fetchSchedules() async {
    _isLoading = true;
    notifyListeners();
    try {
      final docs = await MongoDatabase.schedulesCollection.find().toList();
      _schedules = docs.map((d) => ScheduleModel.fromMongo(d)).toList();
    } catch (e) {
      debugPrint('❌ AdminScheduleViewModel.fetchSchedules: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> publishSchedule(String id) async {
    try {
      await MongoDatabase.schedulesCollection.updateOne(
        {'_id': id},
        {
          '\$set': {'status': 'PUBLISHED'},
        },
      );
      // Update lokal tanpa refetch
      final idx = _schedules.indexWhere((s) => s.id == id);
      if (idx != -1) {
        final old = _schedules[idx];
        _schedules[idx] = ScheduleModel(
          id: old.id,
          namaMatkul: old.namaMatkul,
          namaDosen: old.namaDosen,
          hari: old.hari,
          jamMulai: old.jamMulai,
          jamSelesai: old.jamSelesai,
          ruangan: old.ruangan,
          status: 'PUBLISHED',
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ AdminScheduleViewModel.publishSchedule: $e');
    }
  }
}
