import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/orders/routes/order_routes.dart';
import 'package:little_store_app/src/features/orders/view_models/order_view_model.dart';

class OrdersView extends StatefulWidget {
  final OrderViewModel orderViewModel;

  const OrdersView({super.key, required this.orderViewModel});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.orderViewModel.loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas compras'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: StateBuilderWidget<OrderViewModel, OrdersState>(
        viewModel: widget.orderViewModel,
        builder: (context, state) {
          return switch (state) {
            InitialState() => const Center(child: Text('Nenhum pedido.')),
            LoadingState() => const Center(child: CircularProgressIndicator()),
            SuccessState(data: final orders) when orders.isEmpty => const Center(
              child: Text('Você ainda não fez compras.'),
            ),
            SuccessState(data: final orders) => RefreshIndicator(
              onRefresh: () {
                return widget.orderViewModel.loadOrders();
              },
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text('Pedido #${order.id}'),
                    subtitle: Text('Data da compra: ${order.formattedDate}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(order.formattedTotal),
                        Text(
                          order.status,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    onTap: () {
                      context.push(OrderRoutes.orderDetail, extra: order.id);
                    },
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
                      widget.orderViewModel.loadOrders();
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
