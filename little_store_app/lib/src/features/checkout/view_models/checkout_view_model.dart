import 'package:flutter/foundation.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/cart/models/cart_model.dart';
import 'package:little_store_app/src/features/checkout/exceptions/checkout_exception.dart';
import 'package:little_store_app/src/features/checkout/models/order_summary_model.dart';
import 'package:little_store_app/src/features/checkout/repositories/checkout_repository.dart';

typedef CheckoutPreviewState = AppState<CartModel, CheckoutException>;
typedef CheckoutCompleteState = AppState<OrderSummaryModel, CheckoutException>;

typedef _PreviewViewModel = StateManagement<CheckoutPreviewState>;

abstract interface class CheckoutViewModel extends _PreviewViewModel {
  CheckoutCompleteState get completeState;
  Future<void> loadPreview();
  Future<void> finalizeCheckout();
}

class CheckoutViewModelImpl extends _PreviewViewModel implements CheckoutViewModel {
  final CheckoutRepository checkoutRepository;
  CheckoutCompleteState _completeState = InitialState();

  CheckoutViewModelImpl({required this.checkoutRepository});

  @override
  CheckoutCompleteState get completeState => _completeState;

  @override
  CheckoutPreviewState build() => InitialState();

  @override
  Future<void> loadPreview() async {
    _emit(LoadingState());
    final result = await checkoutRepository.getCartPreview();

    final newState = result.fold<CheckoutPreviewState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );

    _emit(newState);
  }

  @override
  Future<void> finalizeCheckout() async {
    _completeState = LoadingState();
    notifyListeners();

    final result = await checkoutRepository.finalizeCheckout();

    _completeState = result.fold<CheckoutCompleteState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );

    notifyListeners();
    debugPrint('CheckoutViewModel complete: $_completeState');
  }

  void _emit(CheckoutPreviewState newState) {
    emitState(newState);
    debugPrint('CheckoutViewModel preview: $state');
  }
}
