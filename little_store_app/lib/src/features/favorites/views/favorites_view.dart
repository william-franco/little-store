import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/favorites/view_models/favorite_view_model.dart';
import 'package:little_store_app/src/features/products/view_models/product_view_model.dart';

class FavoritesView extends StatefulWidget {
  final FavoriteViewModel favoriteViewModel;

  const FavoritesView({super.key, required this.favoriteViewModel});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.favoriteViewModel.loadFavorites();
    });
  }

  Future<void> _addToCart(int productId) async {
    final success = await locator<ProductViewModel>().addToCart(productId);
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
        title: const Text('Favoritos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: StateBuilderWidget<FavoriteViewModel, FavoritesState>(
        viewModel: widget.favoriteViewModel,
        builder: (context, state) {
          return switch (state) {
            InitialState() => const Center(child: Text('Nenhum favorito.')),
            LoadingState() => const Center(child: CircularProgressIndicator()),
            SuccessState(data: final products) when products.isEmpty =>
              const Center(child: Text('Você ainda não favoritou produtos.')),
            SuccessState(data: final products) => RefreshIndicator(
              onRefresh: () {
                return widget.favoriteViewModel.loadFavorites();
              },
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.description}\n${product.formattedPrice}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined),
                            onPressed: () {
                              _addToCart(product.id);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () {
                              widget.favoriteViewModel.removeFavorite(
                                product.id,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ErrorState(error: final error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro: ${error.message}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      widget.favoriteViewModel.loadFavorites();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          };
        },
      ),
    );
  }
}
