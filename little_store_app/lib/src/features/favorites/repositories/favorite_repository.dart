import 'package:little_store_app/src/common/constants/api_constant.dart';
import 'package:little_store_app/src/common/patterns/result_pattern.dart';
import 'package:little_store_app/src/common/services/connection_service.dart';
import 'package:little_store_app/src/common/services/http_service.dart';
import 'package:little_store_app/src/features/favorites/exceptions/favorite_exception.dart';
import 'package:little_store_app/src/features/products/models/product_model.dart';

typedef FavoritesResult = Result<List<ProductModel>, FavoriteException>;
typedef FavoriteActionResult = Result<void, FavoriteException>;
typedef IsFavoriteResult = Result<bool, FavoriteException>;

abstract interface class FavoriteRepository {
  Future<FavoritesResult> findAllFavorites();
  Future<IsFavoriteResult> isFavorite(int productId);
  Future<FavoriteActionResult> addFavorite(int productId);
  Future<FavoriteActionResult> removeFavorite(int productId);
}

class FavoriteRepositoryImpl implements FavoriteRepository {
  final ConnectionService connectionService;
  final HttpService httpService;

  FavoriteRepositoryImpl({
    required this.connectionService,
    required this.httpService,
  });

  @override
  Future<FavoritesResult> findAllFavorites() async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: FavoriteException('Dispositivo sem conexão.'));
      }

      final result = await httpService.getData(path: ApiConstant.favorites);

      if (result.statusCode == 200 && result.data != null) {
        final products = (result.data as List)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return SuccessResult(value: products);
      }

      return ErrorResult(
        error: FavoriteException(
          'Falha ao carregar favoritos: ${result.statusCode}',
        ),
      );
    } catch (error) {
      return ErrorResult(error: FavoriteException('Erro inesperado: $error'));
    }
  }

  @override
  Future<IsFavoriteResult> isFavorite(int productId) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: FavoriteException('Dispositivo sem conexão.'));
      }

      final result = await httpService.getData(
        path: '${ApiConstant.favorites}/$productId',
      );

      if (result.statusCode == 200 && result.data != null) {
        final data = result.data as Map<String, dynamic>;
        return SuccessResult(value: data['isFavorite'] as bool? ?? false);
      }

      return ErrorResult(
        error: FavoriteException(
          'Falha ao verificar favorito: ${result.statusCode}',
        ),
      );
    } catch (error) {
      return ErrorResult(error: FavoriteException('Erro inesperado: $error'));
    }
  }

  @override
  Future<FavoriteActionResult> addFavorite(int productId) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: FavoriteException('Dispositivo sem conexão.'));
      }

      final result = await httpService.postData(
        path: ApiConstant.favorites,
        body: {'productId': productId},
      );

      if (result.statusCode == 200 ||
          result.statusCode == 201 ||
          result.statusCode == 409) {
        return SuccessResult(value: null);
      }

      return ErrorResult(
        error: FavoriteException(
          'Falha ao favoritar: ${result.statusCode}',
        ),
      );
    } catch (error) {
      return ErrorResult(error: FavoriteException('Erro inesperado: $error'));
    }
  }

  @override
  Future<FavoriteActionResult> removeFavorite(int productId) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: FavoriteException('Dispositivo sem conexão.'));
      }

      final result = await httpService.deleteData(
        path: '${ApiConstant.favorites}/$productId',
      );

      if (result.statusCode == 204) {
        return SuccessResult(value: null);
      }

      return ErrorResult(
        error: FavoriteException(
          'Falha ao remover favorito: ${result.statusCode}',
        ),
      );
    } catch (error) {
      return ErrorResult(error: FavoriteException('Erro inesperado: $error'));
    }
  }
}
