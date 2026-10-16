import 'package:mongo_dart/mongo_dart.dart';

Future<List<Map<String, dynamic>>> loadCartItems(
    Db db, ObjectId userId) async {
  final cart = await db.collection('carts').findOne(where.eq('userId', userId));
  final raw = (cart?['items'] as List?) ?? const [];
  return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

Future<void> saveCartItems(
    Db db, ObjectId userId, List<Map<String, dynamic>> items) async {
  await db.collection('carts').updateOne(
        where.eq('userId', userId),
        modify.set('items', items),
        upsert: true,
      );
}

/// Cart lines joined with live product data (price, name, stock).
Future<Map<String, dynamic>> buildCart(Db db, ObjectId userId) async {
  final items = await loadCartItems(db, userId);
  final ids = items.map((e) => e['productId']).toList();
  final products = ids.isEmpty
      ? <Map<String, dynamic>>[]
      : await db.collection('products').find({
          '_id': {'\$in': ids}
        }).toList();
  final byId = {
    for (final p in products) (p['_id'] as ObjectId).toHexString(): p,
  };

  final lines = <Map<String, dynamic>>[];
  var total = 0.0;
  var count = 0;
  for (final item in items) {
    final pid = item['productId'] as ObjectId;
    final product = byId[pid.toHexString()];
    if (product == null) continue;
    final qty = (item['quantity'] as num).toInt();
    final price = (product['price'] as num).toDouble();
    total += price * qty;
    count += qty;
    lines.add({
      'productId': pid,
      'name': product['name'],
      'price': price,
      'imageUrl': product['imageUrl'],
      'stock': product['stock'],
      'quantity': qty,
      'subtotal': price * qty,
    });
  }
  return {'items': lines, 'total': total, 'count': count};
}
