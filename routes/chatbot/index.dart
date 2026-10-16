import 'package:dart_frog/dart_frog.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/services/chatbot_service.dart';
import 'package:phsardrop_backend/utils/responses.dart';

/// POST {message, history: [{role: user|assistant, content}]}
/// Works for guests too; logged-in users also get their orders as context.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return methodNotAllowed();

  final body = await readBody(context);
  final message = (body['message'] as String?)?.trim() ?? '';
  if (message.isEmpty || message.length > 1000) {
    return fail('message is required (max 1000 characters)');
  }

  final history = <Map<String, String>>[];
  final rawHistory = body['history'];
  if (rawHistory is List) {
    for (final item in rawHistory.take(10)) {
      if (item is Map &&
          (item['role'] == 'user' || item['role'] == 'assistant') &&
          item['content'] is String) {
        history.add({
          'role': item['role'] as String,
          'content': item['content'] as String,
        });
      }
    }
  }
  while (history.isNotEmpty && history.first['role'] != 'user') {
    history.removeAt(0);
  }

  final user = await authenticate(context);
  final reply = await ChatbotService.reply(
    db: await Mongo.db,
    message: message,
    history: history,
    userId: user?.id,
  );
  return ok({'reply': reply});
}
