import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstant {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5064';
    if (Platform.isAndroid) return 'http://10.0.2.2:5064';
    return 'http://localhost:5064';
  }

  static String get authRegister => '/auth/register';
  static String get authLogin => '/auth/login';
  static String get authLogout => '/auth/logout';
  static String get authMe => '/auth/me';
  static String get products => '/products';
  static String get cart => '/cart';
  static String get orders => '/orders';
  static String get ordersCheckout => '/orders/checkout';
  static String get favorites => '/favorites';
}
