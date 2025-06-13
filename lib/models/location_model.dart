import 'package:pocketbase/pocketbase.dart';

class Location {
  final String id;
  final String name;
  final String district;
  final String city;
  final String province;
  final double latitude;
  final double longitude;

  Location({
    required this.id,
    required this.name,
    required this.district,
    required this.city,
    required this.province,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromRecord(RecordModel record) {
    return Location(
      id: record.id,
      name: record.data['name'] ?? '',
      district: record.data['district'] ?? '',
      city: record.data['city'] ?? '',
      province: record.data['province'] ?? '',
      latitude: record.data['latitude'] ?? 0.0,
      longitude: record.data['longitude'] ?? 0.0,
    );
  }
}
