enum OrderStatus {
  preparing,
  ready,
  completed,
}

class Order {
  final String id;
  final String cafeName;
  final List<String> items;
  final double total;
  final OrderStatus status;
  final DateTime orderTime;
  final DateTime estimatedTime;

  Order({
    required this.id,
    required this.cafeName,
    required this.items,
    required this.total,
    required this.status,
    required this.orderTime,
    required this.estimatedTime,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      cafeName: json['cafeName'],
      items: List<String>.from(json['items']),
      total: json['total'].toDouble(),
      status: OrderStatus.values[json['status']],
      orderTime: DateTime.parse(json['orderTime']),
      estimatedTime: DateTime.parse(json['estimatedTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cafeName': cafeName,
      'items': items,
      'total': total,
      'status': status.index,
      'orderTime': orderTime.toIso8601String(),
      'estimatedTime': estimatedTime.toIso8601String(),
    };
  }
}
