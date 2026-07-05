class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }

  String get formattedLineTotal => 'R\$ ${lineTotal.toStringAsFixed(2)}';
}

class OrderSummaryModel {
  final int id;
  final double total;
  final String status;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderSummaryModel({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List)
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return OrderSummaryModel(
      id: json['id'] as int,
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: items,
    );
  }

  String get formattedTotal => 'R\$ ${total.toStringAsFixed(2)}';

  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString();
    return '$day/$month/$year';
  }
}
