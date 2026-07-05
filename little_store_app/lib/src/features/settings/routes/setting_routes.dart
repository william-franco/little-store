import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/features/settings/view_models/setting_view_model.dart';
import 'package:little_store_app/src/features/settings/views/setting_view.dart';

class SettingRoutes {
  static String get setting => '/setting';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: setting,
      builder: (context, state) {
        return SettingView(settingViewModel: locator<SettingViewModel>());
      },
    ),
  ];
}
