import 'package:little_store_app/src/common/constants/api_constant.dart';
import 'package:little_store_app/src/common/patterns/result_pattern.dart';
import 'package:little_store_app/src/common/services/connection_service.dart';
import 'package:little_store_app/src/common/services/http_service.dart';
import 'package:little_store_app/src/features/products/exceptions/product_exception.dart';
import 'package:little_store_app/src/features/products/models/product_model.dart';

typedef ProductsResult = Result<List<ProductModel>, ProductException>;
typedef ProductActionResult = Result<void, ProductException>;

abstract interface class ProductRepository {
  Future<ProductsResult> findProducts({String? search});
  Future<ProductActionResult> addToCart({required int productId, int quantity = 1});
}

class ProductRepositoryImpl implements ProductRepository {
  final ConnectionService connectionService;
  final HttpService httpService;

  ProductRepositoryImpl({
    required this.connectionService,
    required this.httpService,
  });

  @override
  Future<ProductsResult> findProducts({String? search}) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: ProductException('Dispositivo sem conexão.'));
      }

      final path = search != null && search.trim().isNotEmpty
          ? '${ApiConstant.products}?search=${Uri.encodeQueryComponent(search.trim())}'
          : ApiConstant.products;

      final result = await httpService.getData(path: path);

      if (result.statusCode == 200 && result.data != null) {
        final products = (result.data as List)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return SuccessResult(value: products);
      }

      return ErrorResult(
        error: ProductException('Falha ao buscar produtos: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: ProductException('Erro inesperado: $error'));
    }
  }

  @override
  Future<ProductActionResult> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: ProductException('Dispositivo sem conexão.'));
      }

      final result = await httpService.postData(
        path: '${ApiConstant.cart}/items',
        body: {'productId': productId, 'quantity': quantity},
      );

      if (result.statusCode == 200 || result.statusCode == 201) {
        return SuccessResult(value: null);
      }

      return ErrorResult(
        error: ProductException('Falha ao adicionar ao carrinho: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: ProductException('Erro inesperado: $error'));
    }
  }
}
