import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/features/cart/view_models/cart_view_model.dart';
import 'package:little_store_app/src/features/favorites/view_models/favorite_view_model.dart';
import 'package:little_store_app/src/features/products/models/product_model.dart';
import 'package:little_store_app/src/features/products/view_models/product_view_model.dart';

class ProductDetailView extends StatefulWidget {
  final ProductModel product;
  final ProductViewModel productViewModel;
  final CartViewModel cartViewModel;
  final FavoriteViewModel favoriteViewModel;

  const ProductDetailView({
    super.key,
    required this.product,
    required this.productViewModel,
    required this.cartViewModel,
    required this.favoriteViewModel,
  });

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  bool _isFavorite = false;
  bool _loadingFavorite = true;
  bool _togglingFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadFavoriteStatus();
    });
  }

  Future<void> _loadFavoriteStatus() async {
    final isFavorite = await widget.favoriteViewModel.checkIsFavorite(
      widget.product.id,
    );
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
        _loadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _togglingFavorite = true;
    });

    final success = await widget.favoriteViewModel.toggleFavorite(
      productId: widget.product.id,
      isCurrentlyFavorite: _isFavorite,
    );

    if (mounted) {
      setState(() {
        _togglingFavorite = false;
        if (success) {
          _isFavorite = !_isFavorite;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (_isFavorite
                      ? 'Produto adicionado aos favoritos'
                      : 'Produto removido dos favoritos')
                : 'Erro ao atualizar favorito',
          ),
        ),
      );
    }
  }

  Future<void> _addToCart() async {
    final success = await widget.productViewModel.addToCart(widget.product.id);
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
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do produto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          if (_loadingFavorite)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              onPressed: _togglingFavorite
                  ? null
                  : () {
                      _toggleFavorite();
                    },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              product.formattedPrice,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              product.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Cadastrado em'),
              subtitle: Text(product.formattedCreatedAt),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.update_outlined),
              title: const Text('Atualizado em'),
              subtitle: Text(product.formattedUpdatedAt),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  _addToCart();
                },
                child: const Text('Adicionar ao carrinho'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _togglingFavorite || _loadingFavorite
                    ? null
                    : () {
                        _toggleFavorite();
                      },
                child: Text(
                  _isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
