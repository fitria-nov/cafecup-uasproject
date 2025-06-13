import 'package:pocketbase/pocketbase.dart'; // Pastikan impor ini ada

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      category: json['category'],
    );
  }

  factory MenuItem.fromRecord(RecordModel record) {
    return MenuItem(
      id: record.id,
      name: record.data['name'] as String,
      description: record.data['description'] as String,
      price: (record.data['price'] as num).toDouble(),
      imageUrl: record.data['imageUrl'] as String,
      category: record.data['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
    };
  }
}