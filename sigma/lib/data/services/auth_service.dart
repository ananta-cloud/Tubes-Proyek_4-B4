import 'package:mongo_dart/mongo_dart.dart';
import '../../../../core/network/mongo_database.dart';

class AuthService {
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final user = await MongoDatabase.runSafe(
      () => MongoDatabase.usersCollection.findOne(
        where.eq("email", email).eq("password", password),
      ),
    );

    return user;
  }
}
