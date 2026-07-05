import 'package:little_store_app/src/common/constants/api_constant.dart';
import 'package:little_store_app/src/common/patterns/result_pattern.dart';
import 'package:little_store_app/src/common/services/connection_service.dart';
import 'package:little_store_app/src/common/services/http_service.dart';
import 'package:little_store_app/src/features/cart/exceptions/cart_exception.dart';
import 'package:little_store_app/src/features/cart/models/cart_model.dart';

typedef CartResult = Result<CartModel, CartException>;
typedef CartActionResult = Result<void, CartException>;

abstract interface class CartRepository {
  Future<CartResult> getCart();
  Future<CartActionResult> updateQuantity({required int itemId, required int quantity});
  Future<CartActionResult> removeItem(int itemId);
}

class CartRepositoryImpl implements CartRepository {
  final ConnectionService connectionService;
  final HttpService httpService;

  CartRepositoryImpl({
    required this.connectionService,
    required this.httpService,
  });

  @override
  Future<CartResult> getCart() async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: CartException('Dispositivo sem conexão.'));
      }

      final result = await httpService.getData(path: ApiConstant.cart);

      if (result.statusCode == 200 && result.data != null) {
        final cart = CartModel.fromJson(result.data as Map<String, dynamic>);
        return SuccessResult(value: cart);
      }

      return ErrorResult(
        error: CartException('Falha ao carregar carrinho: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: CartException('Erro inesperado: $error'));
    }
  }

  @override
  Future<CartActionResult> updateQuantity({
    required int itemId,
    required int quantity,
  }) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: CartException('Dispositivo sem conexão.'));
      }

      final result = await httpService.putData(
        path: '${ApiConstant.cart}/items/$itemId',
        body: {'quantity': quantity},
      );

      if (result.statusCode == 200) {
        return SuccessResult(value: null);
      }

      return ErrorResult(
        error: CartException('Falha ao atualizar item: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: CartException('Erro inesperado: $error'));
    }
  }

  @override
  Future<CartActionResult> removeItem(int itemId) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: CartException('Dispositivo sem conexão.'));
      }

      final result = await httpService.deleteData(
        path: '${ApiConstant.cart}/items/$itemId',
      );

      if (result.statusCode == 204) {
        return SuccessResult(value: null);
      }

      return ErrorResult(
        error: CartException('Falha ao remover item: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: CartException('Erro inesperado: $error'));
    }
  }
}
