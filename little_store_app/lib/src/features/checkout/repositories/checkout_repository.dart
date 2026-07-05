import 'package:little_store_app/src/common/constants/api_constant.dart';
import 'package:little_store_app/src/common/patterns/result_pattern.dart';
import 'package:little_store_app/src/common/services/connection_service.dart';
import 'package:little_store_app/src/common/services/http_service.dart';
import 'package:little_store_app/src/features/cart/models/cart_model.dart';
import 'package:little_store_app/src/features/checkout/exceptions/checkout_exception.dart';
import 'package:little_store_app/src/features/checkout/models/order_summary_model.dart';

typedef CartPreviewResult = Result<CartModel, CheckoutException>;
typedef CheckoutResult = Result<OrderSummaryModel, CheckoutException>;

abstract interface class CheckoutRepository {
  Future<CartPreviewResult> getCartPreview();
  Future<CheckoutResult> finalizeCheckout();
}

class CheckoutRepositoryImpl implements CheckoutRepository {
  final ConnectionService connectionService;
  final HttpService httpService;

  CheckoutRepositoryImpl({
    required this.connectionService,
    required this.httpService,
  });

  @override
  Future<CartPreviewResult> getCartPreview() async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: CheckoutException('Dispositivo sem conexão.'));
      }

      final result = await httpService.getData(path: ApiConstant.cart);

      if (result.statusCode == 200 && result.data != null) {
        final cart = CartModel.fromJson(result.data as Map<String, dynamic>);
        return SuccessResult(value: cart);
      }

      return ErrorResult(
        error: CheckoutException('Falha ao carregar resumo: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: CheckoutException('Erro inesperado: $error'));
    }
  }

  @override
  Future<CheckoutResult> finalizeCheckout() async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: CheckoutException('Dispositivo sem conexão.'));
      }

      final result = await httpService.postData(
        path: ApiConstant.ordersCheckout,
        body: {},
      );

      if (result.statusCode == 200 && result.data != null) {
        final order = OrderSummaryModel.fromJson(
          result.data as Map<String, dynamic>,
        );
        return SuccessResult(value: order);
      }

      final message = result.data is Map
          ? (result.data as Map)['message']?.toString()
          : null;

      return ErrorResult(
        error: CheckoutException(
          message ?? 'Falha ao finalizar compra: ${result.statusCode}',
        ),
      );
    } catch (error) {
      return ErrorResult(error: CheckoutException('Erro inesperado: $error'));
    }
  }
}
