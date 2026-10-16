import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/config/env.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/serialize.dart';

class AuthUser {
  AuthUser(this.id, this.role, this.token);

  final ObjectId id;
  final String role;
  final String token;

  bool get isAdmin => role == 'admin';
  String get idHex => id.toHexString();
}

String issueToken(ObjectId userId, String role) {
  return JWT({'sub': userId.toHexString(), 'role': role})
      .sign(SecretKey(Env.jwtSecret), expiresIn: const Duration(days: 7));
}

/// Returns the logged-in user, or null when the token is missing,
/// invalid, expired or revoked (logged out).
Future<AuthUser?> authenticate(RequestContext context) async {
  final header = context.request.headers['authorization'];
  if (header == null || !header.startsWith('Bearer ')) return null;
  final token = header.substring(7).trim();
  try {
    final jwt = JWT.verify(token, SecretKey(Env.jwtSecret));
    final payload = Map<String, dynamic>.from(jwt.payload as Map);
    final id = parseId(payload['sub'] as String?);
    if (id == null) return null;
    final db = await Mongo.db;
    final revoked =
        await db.collection('revoked_tokens').findOne(where.eq('token', token));
    if (revoked != null) return null;
    return AuthUser(id, (payload['role'] as String?) ?? 'customer', token);
  } catch (_) {
    return null;
  }
}
