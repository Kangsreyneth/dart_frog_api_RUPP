import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/responses.dart';

Future<Response> onRequest(RequestContext context) async {
  final categories = (await Mongo.db).collection('categories');

  switch (context.request.method) {
    case HttpMethod.get:
      return ok(await categories.find(where.sortBy('name')).toList());
    case HttpMethod.post:
      final user = await authenticate(context);
      if (user == null || !user.isAdmin) return fail('Admin only', 403);
      final body = await readBody(context);
      final name = (body['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) return fail('Name is required');
      final doc = <String, dynamic>{
        '_id': ObjectId(),
        'name': name,
        'imageUrl': body['imageUrl'] ?? '',
      };
      await categories.insertOne(doc);
      return ok(doc, status: 201);
    default:
      return methodNotAllowed();
  }
}
