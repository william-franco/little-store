import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/features/checkout/models/order_summary_model.dart';
import 'package:little_store_app/src/features/checkout/view_models/checkout_view_model.dart';
import 'package:little_store_app/src/features/checkout/views/checkout_view.dart';

class CheckoutRoutes {
  static String get checkout => '/checkout';
  static String get confirmation => '/checkout/confirmation';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: checkout,
      builder: (context, state) {
        return CheckoutView(checkoutViewModel: locator<CheckoutViewModel>());
      },
    ),
    GoRoute(
      path: confirmation,
      builder: (context, state) {
        return CheckoutConfirmationView(
          order: state.extra as OrderSummaryModel,
        );
      },
    ),
  ];
}
