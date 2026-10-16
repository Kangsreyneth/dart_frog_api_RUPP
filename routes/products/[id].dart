import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:phsardrop_backend/db/mongo.dart';
import 'package:phsardrop_backend/utils/responses.dart';
import 'package:phsardrop_backend/utils/serialize.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) return methodNotAllowed();
  final oid = parseId(id);
  if (oid == null) return fail('Invalid product id');
  final doc =
      await (await Mongo.db).collection('products').findOne(where.id(oid));
  return doc == null ? fail('Product not found', 404) : ok(doc);
}
