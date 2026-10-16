import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:phsardrop_backend/utils/serialize.dart';

Response ok(Object? data, {int status = HttpStatus.ok}) =>
    Response.json(statusCode: status, body: serialize(data));

Response fail(String message, [int status = HttpStatus.badRequest]) =>
    Response.json(statusCode: status, body: {'error': message});

Response methodNotAllowed() => fail('Method not allowed', 405);

Future<Map<String, dynamic>> readBody(RequestContext context) async {
  try {
    final body = await context.request.json();
    if (body is Map) return Map<String, dynamic>.from(body);
  } catch (_) {}
  return {};
}
