import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/features/cart/view_models/cart_view_model.dart';
import 'package:little_store_app/src/features/cart/views/cart_view.dart';

class CartRoutes {
  static String get cart => '/cart';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: cart,
      builder: (context, state) {
        return CartView(cartViewModel: locator<CartViewModel>());
      },
    ),
  ];
}
