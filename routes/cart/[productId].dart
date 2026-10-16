import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/services/cart_service.dart';
import 'package:phsardrop_backend/utils/responses.dart';
import 'package:phsardrop_backend/utils/serialize.dart';

/// PUT {quantity} sets a line quantity (0 removes it). DELETE removes it.
Future<Response> onRequest(RequestContext context, String productId) async {
  final user = await authenticate(context);
  if (user == null) return fail('Unauthorized', 401);
  final pid = parseId(productId);
  if (pid == null) return fail('Invalid product id');
  final db = await Mongo.db;

  final items = await loadCartItems(db, user.id);
  final idx = items.indexWhere(
      (e) => (e['productId'] as ObjectId).toHexString() == pid.toHexString());
  if (idx < 0) return fail('Item not in cart', 404);

  switch (context.request.method) {
    case HttpMethod.put:
      final body = await readBody(context);
      final qty = (body['quantity'] as num?)?.toInt();
      if (qty == null || qty < 0) return fail('quantity must be 0 or more');
      if (qty == 0) {
        items.removeAt(idx);
      } else {
        final product = await db.collection('products').findOne(where.id(pid));
        if (product == null) return fail('Product not found', 404);
        if (qty > (product['stock'] as num).toInt()) {
          return fail('Not enough stock');
        }
        items[idx]['quantity'] = qty;
      }
    case HttpMethod.delete:
      items.removeAt(idx);
    default:
      return methodNotAllowed();
  }
  await saveCartItems(db, user.id, items);
  return ok(await buildCart(db, user.id));
}
