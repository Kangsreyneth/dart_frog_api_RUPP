import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

const _cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

Handler middleware(Handler handler) {
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return Response(statusCode: HttpStatus.noContent, headers: _cors);
    }
    try {
      final response = await handler(context);
      return response.copyWith(headers: {...response.headers, ..._cors});
    } catch (e, st) {
      stderr.writeln('Unhandled error: $e\n$st');
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'Internal server error'},
        headers: _cors,
      );
    }
  };
}
