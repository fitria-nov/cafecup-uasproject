import 'package:pocketbase/pocketbase.dart';

class Cafe {
  final String id;
  final String name;
  final String address;
  final double rating;
  final double distance;
  final String imageUrl;
  final bool isOpen;
  final List<String> specialties;
  final String description; // Tambah field ini

  Cafe({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.distance,
    required this.imageUrl,
    required this.isOpen,
    required this.specialties,
    required this.description,
  });

  factory Cafe.fromJson(Map<String, dynamic> json) {
    return Cafe(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      rating: json['rating'].toDouble(),
      distance: json['distance'].toDouble(),
      imageUrl: json['imageUrl'],
      isOpen: json['isOpen'],
      specialties: List<String>.from(json['specialties']),
      description: json['description'],
    );
  }

  factory Cafe.fromRecord(RecordModel record) {
    return Cafe(
      id: record.id,
      name: record.data['name'] as String,
      address: record.data['address'] as String,
      rating: (record.data['rating'] as num).toDouble(),
      distance: (record.data['distance'] as num).toDouble(),
      imageUrl: record.data['imageUrl'] as String,
      isOpen: record.data['isOpen'] as bool,
      specialties: (record.data['specialties'] as List<dynamic>).cast<String>(),
      description: record.data['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'distance': distance,
      'imageUrl': imageUrl,
      'isOpen': isOpen,
      'specialties': specialties,
      'description': description,
    };
  }
}