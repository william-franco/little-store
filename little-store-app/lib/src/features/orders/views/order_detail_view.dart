import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:little_store_app/src/features/checkout/models/order_summary_model.dart';
import 'package:little_store_app/src/features/orders/exceptions/order_exception.dart';
import 'package:little_store_app/src/features/orders/repositories/order_repository.dart';

class OrderDetailView extends StatefulWidget {
  final int orderId;

  const OrderDetailView({super.key, required this.orderId});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  OrderSummaryModel? _order;
  OrderException? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadOrder();
    });
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await locator<OrderRepository>().findOrderById(widget.orderId);

    result.fold(
      onSuccess: (value) {
        setState(() {
          _order = value;
          _loading = false;
        });
      },
      onError: (error) {
        setState(() {
          _error = error;
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.orderId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro: ${_error!.message}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      _loadOrder();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Data da compra'),
                  subtitle: Text(_order!.formattedDate),
                ),
                Text(
                  'Status: ${_order!.status}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Total: ${_order!.formattedTotal}'),
                const Divider(height: 32),
                ..._order!.items.map(
                  (item) => ListTile(
                    title: Text(item.productName),
                    subtitle: Text('Qtd: ${item.quantity}'),
                    trailing: Text(item.formattedLineTotal),
                  ),
                ),
              ],
            ),
    );
  }
}
