import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/responses.dart';
import 'package:phsardrop_backend/utils/serialize.dart';

const _methods = {'khqr', 'card', 'cod'};

/// POST {orderId, method: khqr|card|cod}
///
/// DEMO: khqr/card are marked paid immediately. For production, create the
/// payment as `pending`, return the KHQR/gateway payload, and mark it `paid`
/// from the gateway's webhook (Bakong / ABA PayWay).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return methodNotAllowed();
  final user = await authenticate(context);
  if (user == null) return fail('Unauthorized', 401);

  final body = await readBody(context);
  final orderId = parseId(body['orderId'] as String?);
  final method = body['method'] as String? ?? '';
  if (orderId == null || !_methods.contains(method)) {
    return fail('orderId and method (khqr, card, cod) are required');
  }

  final db = await Mongo.db;
  final order = await db.collection('orders').findOne(where.id(orderId));
  if (order == null) return fail('Order not found', 404);
  if ((order['userId'] as ObjectId).toHexString() != user.idHex) {
    return fail('Forbidden', 403);
  }
  if (order['status'] != 'pending') return fail('Order is already processed');

  final paid = method != 'cod';
  final payment = <String, dynamic>{
    '_id': ObjectId(),
    'orderId': orderId,
    'userId': user.id,
    'method': method,
    'amount': order['total'],
    'status': paid ? 'paid' : 'pending',
    'createdAt': DateTime.now().toUtc(),
  };
  await db.collection('payments').insertOne(payment);
  await db.collection('orders').updateOne(
        where.id(orderId),
        modify
            .set('status', paid ? 'paid' : 'confirmed')
            .set('paymentMethod', method),
      );
  return ok(payment, status: 201);
}
