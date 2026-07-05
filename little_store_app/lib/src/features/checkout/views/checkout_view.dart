import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/features/checkout/exceptions/checkout_exception.dart';
import 'package:little_store_app/src/features/checkout/models/order_summary_model.dart';
import 'package:little_store_app/src/features/checkout/routes/checkout_routes.dart';
import 'package:little_store_app/src/features/checkout/view_models/checkout_view_model.dart';
import 'package:little_store_app/src/features/products/routes/product_routes.dart';

class CheckoutView extends StatefulWidget {
  final CheckoutViewModel checkoutViewModel;

  const CheckoutView({super.key, required this.checkoutViewModel});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.checkoutViewModel.loadPreview();
    });
  }

  Future<void> _finalize() async {
    await widget.checkoutViewModel.finalizeCheckout();
    final completeState = widget.checkoutViewModel.completeState;

    if (!mounted) return;

    if (completeState is SuccessState<OrderSummaryModel, CheckoutException>) {
      context.push(CheckoutRoutes.confirmation, extra: completeState.data);
    } else if (completeState is ErrorState<OrderSummaryModel, CheckoutException>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(completeState.error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.checkoutViewModel,
        builder: (context, _) {
          final previewState = widget.checkoutViewModel.state;
          final isFinalizing =
              widget.checkoutViewModel.completeState is LoadingState;

          return switch (previewState) {
            InitialState() => const Center(child: Text('Carregando resumo...')),
            LoadingState() => const Center(child: CircularProgressIndicator()),
            SuccessState(data: final cart) when cart.isEmpty => const Center(
              child: Text('Carrinho vazio. Adicione produtos primeiro.'),
            ),
            SuccessState(data: final cart) => Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Resumo da compra',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...cart.items.map(
                        (item) => ListTile(
                          title: Text(item.productName),
                          subtitle: Text(
                            '${item.formattedUnitPrice} x ${item.quantity}',
                          ),
                          trailing: Text(item.formattedLineTotal),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        title: Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        trailing: Text(
                          cart.formattedTotal,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isFinalizing
                          ? null
                          : () {
                              _finalize();
                            },
                      child: isFinalizing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Finalizar compra'),
                    ),
                  ),
                ),
              ],
            ),
            ErrorState(error: final error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro: ${error.message}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      widget.checkoutViewModel.loadPreview();
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

class CheckoutConfirmationView extends StatelessWidget {
  final dynamic order;

  const CheckoutConfirmationView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compra finalizada'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            context.go(ProductRoutes.products);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Pedido realizado com sucesso!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${order.formattedTotal}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.go(ProductRoutes.products);
                },
                child: const Text('Voltar aos produtos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
