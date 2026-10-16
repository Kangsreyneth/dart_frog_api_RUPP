import 'package:dart_frog/dart_frog.dart';
import 'package:phsardrop_backend/auth/auth_service.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/responses.dart';

/// Stateless JWTs cannot be deleted, so logout stores the token in a
/// revoked list that `authenticate` checks on every request.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return methodNotAllowed();
  final user = await authenticate(context);
  if (user == null) return fail('Unauthorized', 401);

  final db = await Mongo.db;
  await db.collection('revoked_tokens').insertOne({
    'token': user.token,
    'revokedAt': DateTime.now().toUtc(),
  });
  return ok({'message': 'Logged out'});
}
