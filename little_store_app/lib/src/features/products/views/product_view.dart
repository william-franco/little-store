import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/cart/routes/cart_routes.dart';
import 'package:little_store_app/src/features/cart/view_models/cart_view_model.dart';
import 'package:little_store_app/src/features/products/routes/product_routes.dart';
import 'package:little_store_app/src/features/products/view_models/product_view_model.dart';
import 'package:little_store_app/src/features/profile/routes/profile_routes.dart';

class ProductView extends StatefulWidget {
  final ProductViewModel productViewModel;
  final CartViewModel cartViewModel;

  const ProductView({
    super.key,
    required this.productViewModel,
    required this.cartViewModel,
  });

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.productViewModel.loadProducts();
      await widget.cartViewModel.loadCart();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addToCart(int productId) async {
    final success = await widget.productViewModel.addToCart(productId);
    if (success) {
      await widget.cartViewModel.loadCart();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Produto adicionado ao carrinho' : 'Erro ao adicionar',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          ListenableBuilder(
            listenable: widget.cartViewModel,
            builder: (context, _) {
              final count = widget.cartViewModel.itemCount;
              return Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    context.push(CartRoutes.cart);
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push(ProfileRoutes.profile);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar produtos...',
              leading: const Icon(Icons.search),
              onChanged: (value) {
                widget.productViewModel.searchProducts(value);
              },
              onSubmitted: (value) {
                widget.productViewModel.loadProducts(search: value);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                return widget.productViewModel.loadProducts(
                  search: _searchController.text,
                );
              },
              child: StateBuilderWidget<ProductViewModel, ProductsState>(
                viewModel: widget.productViewModel,
                builder: (context, state) {
                  return switch (state) {
                    InitialState() => const Center(
                      child: Text('Nenhum produto carregado.'),
                    ),
                    LoadingState() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    SuccessState(data: final products) when products.isEmpty =>
                      ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('Nenhum produto encontrado.')),
                        ],
                      ),
                    SuccessState(data: final products) => GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return InkWell(
                          onTap: () {
                            context.push(
                              ProductRoutes.productDetail,
                              extra: product,
                            );
                          },
                          child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    product.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  product.formattedPrice,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                    onPressed: () {
                                      _addToCart(product.id);
                                    },
                                    child: const Text('Adicionar'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        );
                      },
                    ),
                    ErrorState(error: final error) => ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(child: Text('Erro: ${error.message}')),
                      ],
                    ),
                  };
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
