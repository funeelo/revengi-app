import 'package:dio/dio.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.revengi.in',
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 30),
    contentType: 'application/json',
  ),
);
