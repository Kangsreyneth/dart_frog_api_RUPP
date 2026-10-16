import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/config/env.dart';

/// Lazily opened, shared MongoDB connection.
class Mongo {
  Mongo._();

  static Db? _db;
  static Future<Db>? _opening;

  static Future<Db> get db async {
    final current = _db;
    if (current != null && current.isConnected) return current;
    return _opening ??= _open();
  }

  static Future<Db> _open() async {
    try {
      final db = await Db.create(Env.mongoUri);
      await db.open();
      try {
        await db.createIndex('users', key: 'email', unique: true);
      } catch (_) {}
      _db = db;
      return db;
    } finally {
      _opening = null;
    }
  }
}
