import 'package:mongo_dart/mongo_dart.dart';
import '../../core/network/mongo_database.dart';
import '../models/task_model.dart';

class TaskService {

  Future<bool> upsertTask(TaskModel task) async {
    try {
      var objectId = ObjectId.fromHexString(task.id);

      var document = {
        '_id':              objectId,
        'id_user':          ObjectId.fromHexString(task.idUser),
        'nama_tugas':       task.namaTugas,
        'deskripsi':        task.deskripsi,
        'id_mk':            task.idMk,
        'nama_mk_snapshot': task.namaMkSnapshot,
        'deadline':         task.deadline,
        'status':           task.status,
        'is_synced':        true,
        'created_at':       task.createdAt,
        'updated_at':       task.updatedAt,
      };

      await MongoDatabase.tasksCollection.update(
        where.id(objectId),
        document,
        upsert: true,
      );
      return true;
    } catch (e) {
      print("Error Upsert Task: $e");
      return false;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await MongoDatabase.tasksCollection
          .remove(where.id(ObjectId.fromHexString(id)));
    } catch (e) {
      print("Error Delete Task: $e");
    }
  }

  Future<List<TaskModel>> fetchTasksByUser(String userId) async {
    try {
      var objectId = ObjectId.fromHexString(userId);
      final results = await MongoDatabase.tasksCollection
          .find(where.eq('id_user', objectId))
          .toList();
      return results.map((map) => TaskModel.fromMongo(map)).toList();
    } catch (e) {
      print("Error Fetch Tasks: $e");
      return [];
    }
  }
}