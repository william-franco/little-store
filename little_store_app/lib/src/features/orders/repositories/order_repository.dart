import 'package:little_store_app/src/common/constants/api_constant.dart';
import 'package:little_store_app/src/common/patterns/result_pattern.dart';
import 'package:little_store_app/src/common/services/connection_service.dart';
import 'package:little_store_app/src/common/services/http_service.dart';
import 'package:little_store_app/src/features/checkout/models/order_summary_model.dart';
import 'package:little_store_app/src/features/orders/exceptions/order_exception.dart';
import 'package:little_store_app/src/features/orders/models/order_list_model.dart';

typedef OrdersResult = Result<List<OrderListModel>, OrderException>;
typedef OrderDetailResult = Result<OrderSummaryModel, OrderException>;

abstract interface class OrderRepository {
  Future<OrdersResult> findAllOrders();
  Future<OrderDetailResult> findOrderById(int id);
}

class OrderRepositoryImpl implements OrderRepository {
  final ConnectionService connectionService;
  final HttpService httpService;

  OrderRepositoryImpl({
    required this.connectionService,
    required this.httpService,
  });

  @override
  Future<OrdersResult> findAllOrders() async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: OrderException('Dispositivo sem conexão.'));
      }

      final result = await httpService.getData(path: ApiConstant.orders);

      if (result.statusCode == 200 && result.data != null) {
        final orders = (result.data as List)
            .map((e) => OrderListModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return SuccessResult(value: orders);
      }

      return ErrorResult(
        error: OrderException('Falha ao carregar pedidos: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: OrderException('Erro inesperado: $error'));
    }
  }

  @override
  Future<OrderDetailResult> findOrderById(int id) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: OrderException('Dispositivo sem conexão.'));
      }

      final result = await httpService.getData(path: '${ApiConstant.orders}/$id');

      if (result.statusCode == 200 && result.data != null) {
        final order = OrderSummaryModel.fromJson(
          result.data as Map<String, dynamic>,
        );
        return SuccessResult(value: order);
      }

      return ErrorResult(
        error: OrderException('Falha ao carregar pedido: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: OrderException('Erro inesperado: $error'));
    }
  }
}
