import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/responses.dart';

Future<Response> onRequest(RequestContext context) async {
  final user = await authenticate(context);
  if (user == null) return fail('Unauthorized', 401);
  final users = (await Mongo.db).collection('users');

  switch (context.request.method) {
    case HttpMethod.get:
      final doc = await users.findOne(where.id(user.id));
      return doc == null ? fail('User not found', 404) : ok(doc);
    case HttpMethod.put:
      final body = await readBody(context);
      final name = (body['name'] as String?)?.trim();
      if (name != null && name.isEmpty) return fail('Name cannot be empty');
      final update = modify;
      if (name != null) update.set('name', name);
      if (body['phone'] is String) update.set('phone', body['phone']);
      if (body['address'] is String) update.set('address', body['address']);
      await users.updateOne(where.id(user.id), update);
      return ok(await users.findOne(where.id(user.id)));
    default:
      return methodNotAllowed();
  }
}
