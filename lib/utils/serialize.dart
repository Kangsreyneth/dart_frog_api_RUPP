import 'package:mongo_dart/mongo_dart.dart';

/// Converts Mongo documents to JSON-safe values (`_id` -> `id`,
/// ObjectId -> hex string, DateTime -> ISO string). Never leaks passwordHash.
dynamic serialize(dynamic value) {
  if (value is ObjectId) return value.toHexString();
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is Map) {
    final out = <String, dynamic>{};
    value.forEach((key, v) {
      if (key == 'passwordHash') return;
      out[key == '_id' ? 'id' : key.toString()] = serialize(v);
    });
    return out;
  }
  if (value is Iterable) return value.map(serialize).toList();
  return value;
}

ObjectId? parseId(String? id) {
  if (id == null || id.length != 24) return null;
  try {
    return ObjectId.fromHexString(id);
  } catch (_) {
    return null;
  }
}
