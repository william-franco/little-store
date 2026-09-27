import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/patterns/state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/cart/view_models/cart_view_model.dart';
import 'package:little_store_app/src/features/checkout/routes/checkout_routes.dart';

class CartView extends StatefulWidget {
  final CartViewModel cartViewModel;

  const CartView({super.key, required this.cartViewModel});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.cartViewModel.loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => widget.cartViewModel.loadCart(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => widget.cartViewModel.loadCart(),
        child: StateBuilderWidget<CartViewModel, CartState>(
        viewModel: widget.cartViewModel,
        builder: (context, state) {
          return switch (state) {
            InitialState() => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Carrinho vazio.')),
              ],
            ),
            LoadingState() => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            ),
            SuccessState(data: final cart) when cart.isEmpty => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Seu carrinho está vazio.')),
              ],
            ),
            SuccessState(data: final cart) => Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(item.productName),
                            subtitle: Text(
                              '${item.formattedUnitPrice} x ${item.quantity}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_outlined),
                                  onPressed: () {
                                    widget.cartViewModel.updateQuantity(
                                      itemId: item.id,
                                      quantity: item.quantity - 1,
                                    );
                                  },
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  icon: const Icon(Icons.add_outlined),
                                  onPressed: () {
                                    widget.cartViewModel.updateQuantity(
                                      itemId: item.id,
                                      quantity: item.quantity + 1,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outlined),
                                  onPressed: () {
                                    widget.cartViewModel.removeItem(item.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            cart.formattedTotal,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            context.push(CheckoutRoutes.checkout);
                          },
                          child: const Text('Ir para checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ErrorState(error: final error) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(child: Text('Erro: ${error.message}')),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton(
                    onPressed: () {
                      widget.cartViewModel.loadCart();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ),
              ],
            ),
          };
        },
      ),
      ),
    );
  }
}
