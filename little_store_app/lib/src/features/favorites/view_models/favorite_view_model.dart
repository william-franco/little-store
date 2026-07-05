import 'package:flutter/foundation.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/favorites/exceptions/favorite_exception.dart';
import 'package:little_store_app/src/features/favorites/repositories/favorite_repository.dart';
import 'package:little_store_app/src/features/products/models/product_model.dart';

typedef FavoritesState = AppState<List<ProductModel>, FavoriteException>;

typedef _ViewModel = StateManagement<FavoritesState>;

abstract interface class FavoriteViewModel extends _ViewModel {
  Future<void> loadFavorites();
  Future<bool> checkIsFavorite(int productId);
  Future<bool> toggleFavorite({
    required int productId,
    required bool isCurrentlyFavorite,
  });
  Future<void> removeFavorite(int productId);
}

class FavoriteViewModelImpl extends _ViewModel implements FavoriteViewModel {
  final FavoriteRepository favoriteRepository;

  FavoriteViewModelImpl({required this.favoriteRepository});

  @override
  FavoritesState build() => InitialState();

  @override
  Future<void> loadFavorites() async {
    _emit(LoadingState());
    final result = await favoriteRepository.findAllFavorites();

    final state = result.fold<FavoritesState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );

    _emit(state);
  }

  @override
  Future<bool> checkIsFavorite(int productId) async {
    final result = await favoriteRepository.isFavorite(productId);
    return result.fold(
      onSuccess: (value) => value,
      onError: (_) => false,
    );
  }

  @override
  Future<bool> toggleFavorite({
    required int productId,
    required bool isCurrentlyFavorite,
  }) async {
    final result = isCurrentlyFavorite
        ? await favoriteRepository.removeFavorite(productId)
        : await favoriteRepository.addFavorite(productId);

    return result.fold(
      onSuccess: (_) => true,
      onError: (error) {
        debugPrint('FavoriteViewModel toggle error: ${error.message}');
        return false;
      },
    );
  }

  @override
  Future<void> removeFavorite(int productId) async {
    final result = await favoriteRepository.removeFavorite(productId);

    result.fold(
      onSuccess: (_) {
        loadFavorites();
      },
      onError: (error) {
        _emit(ErrorState(error: error));
      },
    );
  }

  void _emit(FavoritesState newState) {
    emitState(newState);
    debugPrint('FavoriteViewModel: $state');
  }
}
