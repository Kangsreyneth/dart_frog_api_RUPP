import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return methodNotAllowed();

  final body = await readBody(context);
  final name = (body['name'] as String?)?.trim() ?? '';
  final email = (body['email'] as String?)?.trim().toLowerCase() ?? '';
  final password = body['password'] as String? ?? '';
  if (name.isEmpty || !email.contains('@') || password.length < 6) {
    return fail('Name, a valid email and a password of 6+ characters are required');
  }

  final db = await Mongo.db;
  final users = db.collection('users');
  if (await users.findOne(where.eq('email', email)) != null) {
    return fail('Email is already registered', 409);
  }

  final id = ObjectId();
  final user = <String, dynamic>{
    '_id': id,
    'name': name,
    'email': email,
    'passwordHash': BCrypt.hashpw(password, BCrypt.gensalt()),
    'phone': (body['phone'] as String?)?.trim() ?? '',
    'address': '',
    'role': 'customer',
    'createdAt': DateTime.now().toUtc(),
  };
  await users.insertOne(user);

  return ok({'token': issueToken(id, 'customer'), 'user': user}, status: 201);
}
