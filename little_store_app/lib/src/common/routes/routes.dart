import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/constants/value_constant.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/common/services/storage_service.dart';
import 'package:little_store_app/src/features/auth/routes/auth_routes.dart';
import 'package:little_store_app/src/features/cart/routes/cart_routes.dart';
import 'package:little_store_app/src/features/checkout/routes/checkout_routes.dart';
import 'package:little_store_app/src/features/favorites/routes/favorite_routes.dart';
import 'package:little_store_app/src/features/orders/routes/order_routes.dart';
import 'package:little_store_app/src/features/products/routes/product_routes.dart';
import 'package:little_store_app/src/features/profile/routes/profile_routes.dart';
import 'package:little_store_app/src/features/settings/routes/setting_routes.dart';

class Routes {
  GoRouter get routes => _routes;

  final GoRouter _routes = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AuthRoutes.login,
    redirect: (context, state) {
      final storage = locator<StorageService>();
      final token = storage.getStringValueSync(key: ValueConstant.jwtToken);
      final isLoggedIn = token != null && token.isNotEmpty;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) {
        return AuthRoutes.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return ProductRoutes.products;
      }

      return null;
    },
    routes: [
      ...AuthRoutes().routes,
      ...ProductRoutes().routes,
      ...CartRoutes().routes,
      ...CheckoutRoutes().routes,
      ...ProfileRoutes().routes,
      ...OrderRoutes().routes,
      ...FavoriteRoutes().routes,
      ...SettingRoutes().routes,
    ],
  );
}
