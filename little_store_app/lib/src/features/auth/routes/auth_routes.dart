import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/features/auth/view_models/auth_view_model.dart';
import 'package:little_store_app/src/features/auth/views/login_view.dart';
import 'package:little_store_app/src/features/auth/views/register_view.dart';

class AuthRoutes {
  static String get login => '/auth/login';
  static String get register => '/auth/register';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: login,
      builder: (context, state) {
        return LoginView(authViewModel: locator<AuthViewModel>());
      },
    ),
    GoRoute(
      path: register,
      builder: (context, state) {
        return RegisterView(authViewModel: locator<AuthViewModel>());
      },
    ),
  ];
}
