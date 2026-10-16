import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/services/cart_service.dart';
import 'package:phsardrop_backend/utils/responses.dart';

const deliveryFee = 1.5;

Future<Response> onRequest(RequestContext context) async {
  final user = await authenticate(context);
  if (user == null) return fail('Unauthorized', 401);
  final db = await Mongo.db;

  switch (context.request.method) {
    case HttpMethod.get:
      final list = await db
          .collection('orders')
          .find(where
              .eq('userId', user.id)
              .sortBy('createdAt', descending: true))
          .toList();
      return ok(list);

    case HttpMethod.post:
      final body = await readBody(context);
      final address = body['address'];
      if (address is! Map ||
          address['lat'] is! num ||
          address['lng'] is! num ||
          '${address['label'] ?? ''}'.trim().isEmpty) {
        return fail('address {label, lat, lng} is required');
      }
      final phone = (body['phone'] as String?)?.trim() ?? '';
      if (phone.isEmpty) return fail('Phone number is required');

      final cart = await buildCart(db, user.id);
      final lines = (cart['items'] as List).cast<Map<String, dynamic>>();
      if (lines.isEmpty) return fail('Your cart is empty');
      for (final line in lines) {
        if ((line['quantity'] as int) > (line['stock'] as num).toInt()) {
          return fail('Not enough stock for ${line['name']}');
        }
      }

      final subtotal = cart['total'] as double;
      final orderId = ObjectId();
      final now = DateTime.now().toUtc();
      final geo = {
        'label': '${address['label']}'.trim(),
        'lat': (address['lat'] as num).toDouble(),
        'lng': (address['lng'] as num).toDouble(),
      };
      final order = <String, dynamic>{
        '_id': orderId,
        'userId': user.id,
        'items': [
          for (final l in lines)
            {
              'productId': l['productId'],
              'name': l['name'],
              'price': l['price'],
              'quantity': l['quantity'],
              'imageUrl': l['imageUrl'],
            }
        ],
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': subtotal + deliveryFee,
        'status': 'pending',
        'address': geo,
        'phone': phone,
        'note': (body['note'] as String?)?.trim() ?? '',
        'paymentMethod': null,
        'createdAt': now,
      };
      await db.collection('orders').insertOne(order);
      await db.collection('deliveries').insertOne({
        '_id': ObjectId(),
        'orderId': orderId,
        'userId': user.id,
        'status': 'preparing',
        'address': geo,
        'courier': null,
        'updatedAt': now,
      });
      for (final l in lines) {
        await db.collection('products').updateOne(
              where.id(l['productId'] as ObjectId),
              modify.inc('stock', -(l['quantity'] as int)),
            );
      }
      await saveCartItems(db, user.id, []);
      return ok(order, status: 201);

    default:
      return methodNotAllowed();
  }
}
