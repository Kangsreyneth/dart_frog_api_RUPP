import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/responses.dart';

/// GET /products?category=<id>&q=<text>&group=<artist>
Future<Response> onRequest(RequestContext context) async {
  final products = (await Mongo.db).collection('products');

  switch (context.request.method) {
    case HttpMethod.get:
      final params = context.request.uri.queryParameters;
      final selector = where.sortBy('createdAt', descending: true).limit(100);
      if ((params['category'] ?? '').isNotEmpty) {
        selector.eq('categoryId', params['category']);
      }
      if ((params['group'] ?? '').isNotEmpty) {
        selector.eq('group', params['group']);
      }
      if ((params['q'] ?? '').isNotEmpty) {
        selector.match('name', RegExp.escape(params['q']!),
            caseInsensitive: true);
      }
      final list = await products.find(selector).toList();
      return ok(list);
    case HttpMethod.post:
      final user = await authenticate(context);
      if (user == null || !user.isAdmin) return fail('Admin only', 403);
      final body = await readBody(context);
      final name = (body['name'] as String?)?.trim() ?? '';
      final price = (body['price'] as num?)?.toDouble();
      if (name.isEmpty || price == null || price <= 0) {
        return fail('Name and a positive price are required');
      }
      final doc = <String, dynamic>{
        '_id': ObjectId(),
        'name': name,
        'description': body['description'] ?? '',
        'price': price,
        'imageUrl': body['imageUrl'] ?? '',
        'categoryId': body['categoryId'] ?? '',
        'group': body['group'] ?? '',
        'stock': (body['stock'] as num?)?.toInt() ?? 0,
        'createdAt': DateTime.now().toUtc(),
      };
      await products.insertOne(doc);
      return ok(doc, status: 201);
    default:
      return methodNotAllowed();
  }
}
