class OrderListModel {
  final int id;
  final double total;
  final String status;
  final DateTime createdAt;

  const OrderListModel({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory OrderListModel.fromJson(Map<String, dynamic> json) {
    return OrderListModel(
      id: json['id'] as int,
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
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
