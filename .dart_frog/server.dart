// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/index.dart' as index;
import '../routes/profile/index.dart' as profile_index;
import '../routes/products/index.dart' as products_index;
import '../routes/products/[id].dart' as products_$id;
import '../routes/payments/index.dart' as payments_index;
import '../routes/orders/index.dart' as orders_index;
import '../routes/orders/[id].dart' as orders_$id;
import '../routes/deliveries/[orderId].dart' as deliveries_$order_id;
import '../routes/chatbot/index.dart' as chatbot_index;
import '../routes/categories/index.dart' as categories_index;
import '../routes/cart/index.dart' as cart_index;
import '../routes/cart/[productId].dart' as cart_$product_id;
import '../routes/auth/register.dart' as auth_register;
import '../routes/auth/logout.dart' as auth_logout;
import '../routes/auth/login.dart' as auth_login;

import '../routes/_middleware.dart' as middleware;

void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/', (context) => buildHandler()(context))
    ..mount('/profile', (context) => buildProfileHandler()(context))
    ..mount('/products', (context) => buildProductsHandler()(context))
    ..mount('/payments', (context) => buildPaymentsHandler()(context))
    ..mount('/orders', (context) => buildOrdersHandler()(context))
    ..mount('/deliveries', (context) => buildDeliveriesHandler()(context))
    ..mount('/chatbot', (context) => buildChatbotHandler()(context))
    ..mount('/categories', (context) => buildCategoriesHandler()(context))
    ..mount('/cart', (context) => buildCartHandler()(context))
    ..mount('/auth', (context) => buildAuthHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildProfileHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => profile_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildProductsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => products_$id.onRequest(context,id,))..all('/', (context) => products_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildPaymentsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => payments_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildOrdersHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => orders_$id.onRequest(context,id,))..all('/', (context) => orders_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildDeliveriesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<orderId>', (context,orderId,) => deliveries_$order_id.onRequest(context,orderId,));
  return pipeline.addHandler(router);
}

Handler buildChatbotHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => chatbot_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildCategoriesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => categories_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildCartHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<productId>', (context,productId,) => cart_$product_id.onRequest(context,productId,))..all('/', (context) => cart_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/login', (context) => auth_login.onRequest(context,))..all('/logout', (context) => auth_logout.onRequest(context,))..all('/register', (context) => auth_register.onRequest(context,));
  return pipeline.addHandler(router);
}

