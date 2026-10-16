import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/services/cart_service.dart';
import 'package:phsardrop_backend/utils/responses.dart';
import 'package:phsardrop_backend/utils/serialize.dart';

Future<Response> onRequest(RequestContext context) async {
  final user = await authenticate(context);
  if (user == null) return fail('Unauthorized', 401);
  final db = await Mongo.db;

  switch (context.request.method) {
    case HttpMethod.get:
      return ok(await buildCart(db, user.id));

    case HttpMethod.post:
      final body = await readBody(context);
      final productId = parseId(body['productId'] as String?);
      final qty = (body['quantity'] as num?)?.toInt() ?? 1;
      if (productId == null || qty < 1) {
        return fail('productId and quantity >= 1 are required');
      }
      final product =
          await db.collection('products').findOne(where.id(productId));
      if (product == null) return fail('Product not found', 404);

      final items = await loadCartItems(db, user.id);
      final idx = items.indexWhere((e) =>
          (e['productId'] as ObjectId).toHexString() ==
          productId.toHexString());
      final current = idx >= 0 ? (items[idx]['quantity'] as num).toInt() : 0;
      final next = current + qty;
      if (next > (product['stock'] as num).toInt()) {
        return fail('Not enough stock');
      }
      if (idx >= 0) {
        items[idx]['quantity'] = next;
      } else {
        items.add({'productId': productId, 'quantity': next});
      }
      await saveCartItems(db, user.id, items);
      return ok(await buildCart(db, user.id));

    case HttpMethod.delete:
      await saveCartItems(db, user.id, []);
      return ok(await buildCart(db, user.id));

    default:
      return methodNotAllowed();
  }
}
