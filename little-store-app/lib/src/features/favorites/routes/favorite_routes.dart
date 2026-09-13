import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/features/favorites/view_models/favorite_view_model.dart';
import 'package:little_store_app/src/features/favorites/views/favorites_view.dart';

class FavoriteRoutes {
  static String get favorites => '/favorites';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: favorites,
      builder: (context, state) {
        return FavoritesView(favoriteViewModel: locator<FavoriteViewModel>());
      },
    ),
  ];
}
