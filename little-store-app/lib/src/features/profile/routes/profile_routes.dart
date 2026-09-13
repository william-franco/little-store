import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/features/auth/view_models/auth_view_model.dart';
import 'package:little_store_app/src/features/profile/view_models/profile_view_model.dart';
import 'package:little_store_app/src/features/profile/views/profile_view.dart';

class ProfileRoutes {
  static String get profile => '/profile';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: profile,
      builder: (context, state) {
        return ProfileView(
          profileViewModel: locator<ProfileViewModel>(),
          authViewModel: locator<AuthViewModel>(),
        );
      },
    ),
  ];
}
