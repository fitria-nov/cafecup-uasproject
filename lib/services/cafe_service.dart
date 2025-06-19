import 'dart:developer';
import 'package:pocketbase/pocketbase.dart';
import 'package:geolocator/geolocator.dart';
import '../models/cafe_model.dart';
import 'pocketbase_service.dart';
import 'location_service.dart'; // Import the new LocationService

/// Service class for handling cafe-related operations with PocketBase.
///
/// This class provides methods to fetch cafe data. It uses [LocationService]
/// to calculate the distance from the user to each cafe.
class CafeService {
  final PocketBaseService _pbService = PocketBaseService();
  final LocationService _locationService = LocationService(); // Use the LocationService singleton

  /// Fetches a list of all cafes from PocketBase.
  ///
  /// This method retrieves all records from the 'cafe' collection,
  /// calculates the distance to each cafe using the user's current location
  /// from [LocationService], and sorts the list by distance.
  Future<List<Cafe>> getCafes() async {
    try {
      final pb = _pbService.pb;
      log('🔍 [CafeService] Fetching all cafes...');

      // CORRECTED: Changed 'cafes' to 'cafe' to match the collection name.
      final records = await pb.collection('cafe').getFullList();
      log('✅ [CafeService] Successfully fetched ${records.length} total cafe records.');

      if (records.isEmpty) {
        log('⚠️ [CafeService] No cafe records found in the database.');
        return [];
      }

      // Process records into a list of Cafe objects and sort them.
      return _processRecords(records);

    } catch (e) {
      _handleError('fetching all cafes', e);
      // In case of an error, return an empty list to prevent the UI from crashing.
      return [];
    }
  }

  /// Fetches a list of cafes located in a specific district.
  ///
  /// [district] The name of the district to filter by.
  /// The filter uses a 'contains' operator (`~`) on the 'address' field.
  Future<List<Cafe>> getCafesByDistrict(String district) async {
    try {
      final pb = _pbService.pb;
      log('🔍 [CafeService] Fetching cafes by district: $district');

      // CORRECTED: Changed 'cafes' to 'cafe' to match the collection name.
      final records = await pb.collection('cafe').getFullList(
        filter: 'address ~ "$district"',
      );

      log('✅ [CafeService] Found ${records.length} cafes in district: $district');

      if (records.isEmpty) {
        log('⚠️ [CafeService] No cafe records found for district: $district');
        return [];
      }

      // Process records into a list of Cafe objects and sort them.
      return _processRecords(records);

    } catch (e) {
      _handleError('fetching cafes by district', e);
      return [];
    }
  }

  /// Fetches a single cafe by its unique ID.
  ///
  /// [id] The PocketBase record ID of the cafe.
  Future<Cafe> getCafeById(String id) async {
    try {
      final pb = _pbService.pb;
      log('🔍 [CafeService] Fetching cafe by ID: $id');

      // CORRECTED: Changed 'cafes' to 'cafe' to match the collection name.
      final record = await pb.collection('cafe').getOne(id);
      log('✅ [CafeService] Successfully fetched cafe: ${record.id}');

      // Note: We don't calculate distance for a single cafe view.
      // The user's position is retrieved from LocationService if needed elsewhere.
      return _createCafeFromRecord(record, userPosition: _locationService.currentPosition);

    } catch (e) {
      _handleError('fetching cafe by ID', e);
      throw Exception('Failed to load cafe details: $e');
    }
  }

  /// A helper function to process a list of PocketBase records into Cafe objects.
  ///
  /// This function uses the current location from [LocationService] to calculate
  /// distances and then sorts the cafes accordingly.
  Future<List<Cafe>> _processRecords(List<RecordModel> records) async {
    // Get position directly from the LocationService instance.
    // Assumes LocationService has been initialized elsewhere (e.g., at app startup).
    final Position? userPosition = _locationService.currentPosition;
    final List<Cafe> cafes = [];

    for (var record in records) {
      try {
        final cafe = _createCafeFromRecord(record, userPosition: userPosition);
        cafes.add(cafe);
      } catch (e) {
        log('❌ [CafeService] Error processing a single cafe record (${record.id}): $e');
        // Continue to the next record
      }
    }

    // Sort cafes by distance, from nearest to farthest.
    cafes.sort((a, b) => a.distance.compareTo(b.distance));

    return cafes;
  }

  /// Creates a [Cafe] object from a [RecordModel].
  ///
  /// Safely extracts data from the record, calculates distance if [userPosition]
  /// is provided, and returns a fully populated [Cafe] object.
  Cafe _createCafeFromRecord(RecordModel record, {Position? userPosition}) {
    // Safely extract specialties.
    final specialtiesData = record.data['specialties'];
    final List<String> specialtiesList = specialtiesData is List
        ? specialtiesData.map((item) => item.toString()).toList()
        : [];

    final cafeLat = (record.data['latitude'] ?? 0.0).toDouble();
    final cafeLng = (record.data['longitude'] ?? 0.0).toDouble();

    // Calculate distance if user position is available.
    double distanceInKm = 0.0;
    if (userPosition != null) {
      // Geolocator is still used here for the static distance calculation method.
      final distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        cafeLat,
        cafeLng,
      );
      distanceInKm = distanceInMeters / 1000;
    }

    return Cafe(
      id: record.id,
      name: record.data['name'] ?? 'Unknown Cafe',
      address: record.data['address'] ?? 'No address',
      description: record.data['description'] ?? '',
      // CORRECTED: Changed 'image_url' to 'imageUrl' to match the schema.
      imageUrl: record.data['imageUrl'] ?? '',
      latitude: cafeLat,
      longitude: cafeLng,
      rating: (record.data['rating'] ?? 0.0).toDouble(),
      isOpen: record.data['isOpen'] ?? false,
      distance: distanceInKm,
      specialties: specialtiesList,
    );
  }

  /// A centralized function for logging errors.
  void _handleError(String operation, Object e) {
    log('❌ [CafeService] Error while $operation: $e');
    if (e is ClientException) {
      log('   - URL: ${e.url}');
      log('   - Status Code: ${e.statusCode}');
      log('   - Response: ${e.response}');

    }
  }
}
