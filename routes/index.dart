import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(body: {
    'name': 'PhsarDrop API',
    'status': 'ok',
    'version': '1.0.0',
  });
}
