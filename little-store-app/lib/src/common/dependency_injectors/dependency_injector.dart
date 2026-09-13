import 'package:get_it/get_it.dart';
import 'package:little_store_app/src/common/services/connection_service.dart';
import 'package:little_store_app/src/common/services/http_service.dart';
import 'package:little_store_app/src/common/services/storage_service.dart';
import 'package:little_store_app/src/features/auth/repositories/auth_repository.dart';
import 'package:little_store_app/src/features/auth/view_models/auth_view_model.dart';
import 'package:little_store_app/src/features/cart/repositories/cart_repository.dart';
import 'package:little_store_app/src/features/cart/view_models/cart_view_model.dart';
import 'package:little_store_app/src/features/checkout/repositories/checkout_repository.dart';
import 'package:little_store_app/src/features/checkout/view_models/checkout_view_model.dart';
import 'package:little_store_app/src/features/favorites/repositories/favorite_repository.dart';
import 'package:little_store_app/src/features/favorites/view_models/favorite_view_model.dart';
import 'package:little_store_app/src/features/orders/repositories/order_repository.dart';
import 'package:little_store_app/src/features/orders/view_models/order_view_model.dart';
import 'package:little_store_app/src/features/products/repositories/product_repository.dart';
import 'package:little_store_app/src/features/products/view_models/product_view_model.dart';
import 'package:little_store_app/src/features/profile/repositories/profile_repository.dart';
import 'package:little_store_app/src/features/profile/view_models/profile_view_model.dart';
import 'package:little_store_app/src/features/settings/repositories/setting_repository.dart';
import 'package:little_store_app/src/features/settings/view_models/setting_view_model.dart';

final locator = GetIt.instance;

void dependencyInjector() {
  _registerServices();
  _registerAuth();
  _registerProfile();
  _registerProducts();
  _registerCart();
  _registerCheckout();
  _registerOrders();
  _registerFavorites();
  _registerSettings();
}

void _registerServices() {
  locator.registerLazySingleton<ConnectionService>(
    () => ConnectionServiceImpl(),
  );
  locator.registerLazySingleton<StorageService>(() => StorageServiceImpl());
  locator.registerLazySingleton<HttpService>(
    () => HttpServiceImpl(storageService: locator<StorageService>()),
  );
}

void _registerAuth() {
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
      storageService: locator<StorageService>(),
    ),
  );
  locator.registerLazySingleton<AuthViewModel>(
    () => AuthViewModelImpl(authRepository: locator<AuthRepository>()),
  );
}

void _registerProfile() {
  locator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
    ),
  );
  locator.registerLazySingleton<ProfileViewModel>(
    () => ProfileViewModelImpl(profileRepository: locator<ProfileRepository>()),
  );
}

void _registerProducts() {
  locator.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
    ),
  );
  locator.registerLazySingleton<ProductViewModel>(
    () => ProductViewModelImpl(productRepository: locator<ProductRepository>()),
  );
}

void _registerCart() {
  locator.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
    ),
  );
  locator.registerLazySingleton<CartViewModel>(
    () => CartViewModelImpl(cartRepository: locator<CartRepository>()),
  );
}

void _registerCheckout() {
  locator.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
    ),
  );
  locator.registerLazySingleton<CheckoutViewModel>(
    () => CheckoutViewModelImpl(
      checkoutRepository: locator<CheckoutRepository>(),
    ),
  );
}

void _registerOrders() {
  locator.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
    ),
  );
  locator.registerLazySingleton<OrderViewModel>(
    () => OrderViewModelImpl(orderRepository: locator<OrderRepository>()),
  );
}

void _registerFavorites() {
  locator.registerLazySingleton<FavoriteRepository>(
    () => FavoriteRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
    ),
  );
  locator.registerLazySingleton<FavoriteViewModel>(
    () => FavoriteViewModelImpl(
      favoriteRepository: locator<FavoriteRepository>(),
    ),
  );
}

void _registerSettings() {
  locator.registerLazySingleton<SettingRepository>(
    () => SettingRepositoryImpl(storageService: locator<StorageService>()),
  );
  locator.registerLazySingleton<SettingViewModel>(
    () => SettingViewModelImpl(settingRepository: locator<SettingRepository>()),
  );
}

Future<void> initDependencies() async {
  await locator<StorageService>().initStorage();
  await Future.wait([locator<SettingViewModel>().getTheme()]);
}

void resetDependencies() {
  locator.reset();
}
