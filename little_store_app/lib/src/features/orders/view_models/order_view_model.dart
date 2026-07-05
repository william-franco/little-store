import 'package:flutter/foundation.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/orders/exceptions/order_exception.dart';
import 'package:little_store_app/src/features/orders/models/order_list_model.dart';
import 'package:little_store_app/src/features/orders/repositories/order_repository.dart';

typedef OrdersState = AppState<List<OrderListModel>, OrderException>;

typedef _ViewModel = StateManagement<OrdersState>;

abstract interface class OrderViewModel extends _ViewModel {
  Future<void> loadOrders();
}

class OrderViewModelImpl extends _ViewModel implements OrderViewModel {
  final OrderRepository orderRepository;

  OrderViewModelImpl({required this.orderRepository});

  @override
  OrdersState build() => InitialState();

  @override
  Future<void> loadOrders() async {
    _emit(LoadingState());
    final result = await orderRepository.findAllOrders();

    final state = result.fold<OrdersState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );

    _emit(state);
  }

  void _emit(OrdersState newState) {
    emitState(newState);
    debugPrint('OrderViewModel: $state');
  }
}
