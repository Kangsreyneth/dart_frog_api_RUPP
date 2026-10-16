import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/responses.dart';
import 'package:phsardrop_backend/utils/serialize.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) return methodNotAllowed();
  final user = await authenticate(context);
  if (user == null) return fail('Unauthorized', 401);
  final orderId = parseId(id);
  if (orderId == null) return fail('Invalid order id');

  final db = await Mongo.db;
  final order = await db.collection('orders').findOne(where.id(orderId));
  if (order == null) return fail('Order not found', 404);
  final owner = (order['userId'] as ObjectId).toHexString();
  if (!user.isAdmin && owner != user.idHex) return fail('Forbidden', 403);

  final delivery =
      await db.collection('deliveries').findOne(where.eq('orderId', orderId));
  final payment =
      await db.collection('payments').findOne(where.eq('orderId', orderId));
  return ok({'order': order, 'delivery': delivery, 'payment': payment});
}
