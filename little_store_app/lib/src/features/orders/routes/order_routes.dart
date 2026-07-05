import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/features/orders/view_models/order_view_model.dart';
import 'package:little_store_app/src/features/orders/views/order_detail_view.dart';
import 'package:little_store_app/src/features/orders/views/orders_view.dart';

class OrderRoutes {
  static String get orders => '/orders';
  static String get orderDetail => '/orders/detail';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: orders,
      builder: (context, state) {
        return OrdersView(orderViewModel: locator<OrderViewModel>());
      },
    ),
    GoRoute(
      path: orderDetail,
      builder: (context, state) {
        return OrderDetailView(orderId: state.extra as int);
      },
    ),
  ];
}
