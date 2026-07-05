import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/features/cart/view_models/cart_view_model.dart';
import 'package:little_store_app/src/features/favorites/view_models/favorite_view_model.dart';
import 'package:little_store_app/src/features/products/models/product_model.dart';
import 'package:little_store_app/src/features/products/view_models/product_view_model.dart';
import 'package:little_store_app/src/features/products/views/product_detail_view.dart';
import 'package:little_store_app/src/features/products/views/product_view.dart';

class ProductRoutes {
  static String get products => '/products';
  static String get productDetail => '/products/detail';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: products,
      builder: (context, state) {
        return ProductView(
          productViewModel: locator<ProductViewModel>(),
          cartViewModel: locator<CartViewModel>(),
        );
      },
    ),
    GoRoute(
      path: productDetail,
      builder: (context, state) {
        return ProductDetailView(
          product: state.extra as ProductModel,
          productViewModel: locator<ProductViewModel>(),
          cartViewModel: locator<CartViewModel>(),
          favoriteViewModel: locator<FavoriteViewModel>(),
        );
      },
    ),
  ];
}
