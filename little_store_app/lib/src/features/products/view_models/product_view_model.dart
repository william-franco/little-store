import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/products/exceptions/product_exception.dart';
import 'package:little_store_app/src/features/products/models/product_model.dart';
import 'package:little_store_app/src/features/products/repositories/product_repository.dart';

typedef ProductsState = AppState<List<ProductModel>, ProductException>;

typedef _ViewModel = StateManagement<ProductsState>;

abstract interface class ProductViewModel extends _ViewModel {
  Future<void> loadProducts({String? search});
  void searchProducts(String query);
  Future<bool> addToCart(int productId);
}

class ProductViewModelImpl extends _ViewModel implements ProductViewModel {
  final ProductRepository productRepository;
  Timer? _debounce;

  ProductViewModelImpl({required this.productRepository});

  @override
  ProductsState build() => InitialState();

  @override
  Future<void> loadProducts({String? search}) async {
    _emit(LoadingState());
    final result = await productRepository.findProducts(search: search);

    final state = result.fold<ProductsState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );

    _emit(state);
  }

  @override
  void searchProducts(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      loadProducts(search: query);
    });
  }

  @override
  Future<bool> addToCart(int productId) async {
    final result = await productRepository.addToCart(productId: productId);
    return result.fold(
      onSuccess: (_) => true,
      onError: (_) => false,
    );
  }

  void _emit(ProductsState newState) {
    emitState(newState);
    debugPrint('ProductViewModel: $state');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
