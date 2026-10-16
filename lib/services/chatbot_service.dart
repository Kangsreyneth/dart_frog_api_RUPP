import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/config/env.dart';

class ChatbotService {
  static const _stop = {
    'the', 'and', 'for', 'you', 'have', 'with', 'what', 'how', 'can', 'any',
    'there', 'this', 'that', 'want', 'need', 'about', 'please', 'show', 'get',
  };

  static Future<String> reply({
    required Db db,
    required String message,
    required List<Map<String, String>> history,
    ObjectId? userId,
  }) async {
    final context = await _buildContext(db, message, userId);
    if (Env.anthropicKey.isEmpty) return _fallback(message, context);

    try {
      final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': Env.anthropicKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': Env.chatbotModel,
          'max_tokens': 500,
          'system': _system(context),
          'messages': [
            ...history,
            {'role': 'user', 'content': message},
          ],
        }),
      );
      if (res.statusCode != 200) return _fallback(message, context);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text = (data['content'] as List)
          .whereType<Map>()
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'])
          .join('\n')
          .trim();
      return text.isEmpty ? _fallback(message, context) : text;
    } catch (_) {
      return _fallback(message, context);
    }
  }

  static String _system(_ChatContext c) => '''
You are PhsarDrop Assistant, the support chatbot of PhsarDrop, an online store
for K-pop accessories (lightsticks, photocards, albums, keychains, apparel)
that delivers in Cambodia. Be friendly, short and accurate. Reply in the
language the customer uses (English or Khmer). Only use the data below; if
something is not listed, say you are not sure and suggest contacting support.
Payment methods: KHQR, card, cash on delivery. Delivery fee: \$1.50.

Matching products:
${c.products.isEmpty ? '(none found)' : c.products.join('\n')}

Customer's recent orders:
${c.orders.isEmpty ? '(not logged in or no orders)' : c.orders.join('\n')}
''';

  static Future<_ChatContext> _buildContext(
      Db db, String message, ObjectId? userId) async {
    final tokens = RegExp(r'[a-zA-Z0-9]{3,}')
        .allMatches(message.toLowerCase())
        .map((m) => m.group(0)!)
        .where((t) => !_stop.contains(t))
        .toSet()
        .toList();

    var products = <String>[];
    if (tokens.isNotEmpty) {
      final pattern = tokens.map(RegExp.escape).join('|');
      final found = await db.collection('products').find({
        '\$or': [
          {'name': {'\$regex': pattern, '\$options': 'i'}},
          {'group': {'\$regex': pattern, '\$options': 'i'}},
        ]
      }).take(5).toList();
      products = found
          .map((p) =>
              '- ${p['name']} (${p['group'] ?? 'K-pop'}) - \$${(p['price'] as num).toStringAsFixed(2)}, ${p['stock']} in stock')
          .toList();
    }

    var orders = <String>[];
    if (userId != null) {
      final found = await db
          .collection('orders')
          .find(where.eq('userId', userId).sortBy('createdAt', descending: true))
          .take(3)
          .toList();
      orders = found
          .map((o) =>
              '- Order ${(o['_id'] as ObjectId).toHexString().substring(18)}: ${o['status']}, total \$${(o['total'] as num).toStringAsFixed(2)}')
          .toList();
    }
    return _ChatContext(products, orders);
  }

  static String _fallback(String message, _ChatContext c) {
    final m = message.toLowerCase();
    if (m.contains('order') || m.contains('track')) {
      return c.orders.isEmpty
          ? 'Log in and open the Orders tab to see your order status and live delivery map.'
          : 'Here are your latest orders:\n${c.orders.join('\n')}';
    }
    if (m.contains('pay')) {
      return 'We accept KHQR, card and cash on delivery. You pay after confirming your delivery address.';
    }
    if (m.contains('deliver') || m.contains('ship')) {
      return 'Delivery is \$1.50. Pick your location on the map at checkout and track the courier from the Orders tab.';
    }
    if (c.products.isNotEmpty) {
      return 'I found these items:\n${c.products.join('\n')}';
    }
    return 'Hi! Ask me about K-pop lightsticks, photocards, albums, orders, payment or delivery.';
  }
}

class _ChatContext {
  _ChatContext(this.products, this.orders);
  final List<String> products;
  final List<String> orders;
}
