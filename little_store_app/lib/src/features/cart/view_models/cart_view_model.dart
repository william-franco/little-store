import 'package:flutter/foundation.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/cart/exceptions/cart_exception.dart';
import 'package:little_store_app/src/features/cart/models/cart_model.dart';
import 'package:little_store_app/src/features/cart/repositories/cart_repository.dart';

typedef CartState = AppState<CartModel, CartException>;

typedef _ViewModel = StateManagement<CartState>;

abstract interface class CartViewModel extends _ViewModel {
  int get itemCount;
  Future<void> loadCart();
  Future<void> updateQuantity({required int itemId, required int quantity});
  Future<void> removeItem(int itemId);
}

class CartViewModelImpl extends _ViewModel implements CartViewModel {
  final CartRepository cartRepository;
  int _itemCount = 0;

  CartViewModelImpl({required this.cartRepository});

  @override
  int get itemCount => _itemCount;

  @override
  CartState build() => InitialState();

  @override
  Future<void> loadCart() async {
    _emit(LoadingState());
    final result = await cartRepository.getCart();

    final state = result.fold<CartState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );

    _itemCount = state is SuccessState<CartModel, CartException>
        ? state.data.items.fold<int>(0, (sum, item) => sum + item.quantity)
        : _itemCount;

    _emit(state);
  }

  @override
  Future<void> updateQuantity({required int itemId, required int quantity}) async {
    if (quantity <= 0) {
      await removeItem(itemId);
      return;
    }

    final result = await cartRepository.updateQuantity(
      itemId: itemId,
      quantity: quantity,
    );

    result.fold(
      onSuccess: (_) => loadCart(),
      onError: (error) => _emit(ErrorState(error: error)),
    );
  }

  @override
  Future<void> removeItem(int itemId) async {
    final result = await cartRepository.removeItem(itemId);

    result.fold(
      onSuccess: (_) => loadCart(),
      onError: (error) => _emit(ErrorState(error: error)),
    );
  }

  void _emit(CartState newState) {
    emitState(newState);
    debugPrint('CartViewModel: $state');
  }
}
