class CartItemModel {
  final int id;
  final int productId;
  final String productName;
  final String description;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      description: json['description'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }

  String get formattedLineTotal => 'R\$ ${lineTotal.toStringAsFixed(2)}';
  String get formattedUnitPrice => 'R\$ ${unitPrice.toStringAsFixed(2)}';
}

class CartModel {
  final List<CartItemModel> items;
  final double total;

  const CartModel({required this.items, required this.total});

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List)
        .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CartModel(
      items: items,
      total: (json['total'] as num).toDouble(),
    );
  }

  String get formattedTotal => 'R\$ ${total.toStringAsFixed(2)}';

  bool get isEmpty => items.isEmpty;
}
