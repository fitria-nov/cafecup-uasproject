import 'package:pocketbase/pocketbase.dart';
import 'package:latlong2/latlong.dart';

class Cafe {
  final String id;
  final String name;
  final String address;
  final double rating;
  final double distance;
  final String imageUrl;
  final bool isOpen;
  final List<String> specialties;
  final double latitude;
  final double longitude;
  final String description;

  // Tambahkan getter ini untuk flutter_map
  LatLng get location => LatLng(latitude, longitude);

  Cafe({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.distance,
    required this.imageUrl,
    required this.isOpen,
    required this.specialties,
    required this.latitude,
    required this.longitude,
    required this.description,
  });

  factory Cafe.fromRecord(RecordModel record) {
    return Cafe(
      id: record.id,
      name: record.data['name'] as String? ?? '',
      address: record.data['address'] as String? ?? '',
      rating: (record.data['rating'] as num?)?.toDouble() ?? 0.0,
      distance: (record.data['distance'] as num?)?.toDouble() ?? 0.0,
      imageUrl: record.data['imageUrl'] as String? ?? '',
      isOpen: record.data['isOpen'] as bool? ?? false,
      specialties: record.data['specialties'] != null
          ? (record.data['specialties'] as List<dynamic>).cast<String>()
          : [],
      latitude: (record.data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (record.data['longitude'] as num?)?.toDouble() ?? 0.0,
      description: record.data['description'] as String? ?? '',
    );
  }
}
