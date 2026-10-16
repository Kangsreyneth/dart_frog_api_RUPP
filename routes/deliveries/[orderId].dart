import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/responses.dart';
import 'package:phsardrop_backend/utils/serialize.dart';

const _statuses = {'preparing', 'on_the_way', 'delivered'};

/// GET  -> delivery info for an order (owner or admin)
/// PUT  -> admin/courier updates {status, lat, lng}
Future<Response> onRequest(RequestContext context, String orderId) async {
  final user = await authenticate(context);
  if (user == null) return fail('Unauthorized', 401);
  final oid = parseId(orderId);
  if (oid == null) return fail('Invalid order id');

  final db = await Mongo.db;
  final deliveries = db.collection('deliveries');
  final delivery = await deliveries.findOne(where.eq('orderId', oid));
  if (delivery == null) return fail('Delivery not found', 404);
  final owner = (delivery['userId'] as ObjectId).toHexString();
  if (!user.isAdmin && owner != user.idHex) return fail('Forbidden', 403);

  switch (context.request.method) {
    case HttpMethod.get:
      return ok(delivery);

    case HttpMethod.put:
      if (!user.isAdmin) return fail('Admin only', 403);
      final body = await readBody(context);
      final status = body['status'] as String? ?? delivery['status'] as String;
      if (!_statuses.contains(status)) return fail('Invalid status');

      final update = modify
          .set('status', status)
          .set('updatedAt', DateTime.now().toUtc());
      if (body['lat'] is num && body['lng'] is num) {
        update.set('courier', {
          'lat': (body['lat'] as num).toDouble(),
          'lng': (body['lng'] as num).toDouble(),
        });
      }
      await deliveries.updateOne(where.eq('orderId', oid), update);

      if (status == 'on_the_way') {
        await db
            .collection('orders')
            .updateOne(where.id(oid), modify.set('status', 'shipped'));
      } else if (status == 'delivered') {
        await db
            .collection('orders')
            .updateOne(where.id(oid), modify.set('status', 'delivered'));
        await db.collection('payments').updateOne(
              where.eq('orderId', oid).eq('method', 'cod'),
              modify.set('status', 'paid'),
            );
      }
      return ok(await deliveries.findOne(where.eq('orderId', oid)));

    default:
      return methodNotAllowed();
  }
}
