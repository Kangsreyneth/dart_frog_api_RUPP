import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return methodNotAllowed();

  final body = await readBody(context);
  final email = (body['email'] as String?)?.trim().toLowerCase() ?? '';
  final password = body['password'] as String? ?? '';

  final db = await Mongo.db;
  final user = await db.collection('users').findOne(where.eq('email', email));
  if (user == null ||
      !BCrypt.checkpw(password, user['passwordHash'] as String)) {
    return fail('Invalid email or password', 401);
  }

  final token = issueToken(user['_id'] as ObjectId, user['role'] as String);
  return ok({'token': token, 'user': user});
}
