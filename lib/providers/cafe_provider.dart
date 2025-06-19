import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/cafe_model.dart';
import '../services/cafe_service.dart';
import '../services/location_service.dart';

class CafeProvider with ChangeNotifier {
  final CafeService _cafeService = CafeService();
  final LocationService _locationService = LocationService();

  List<Cafe> _cafes = [];
  Map<String, Marker> _markers = {};
  bool _isLoading = false;
  String? _error;
  Cafe? _selectedCafe;
  BitmapDescriptor? _cafeMarkerIcon;

  // Getters
  List<Cafe> get cafes => _cafes;
  Set<Marker> get markers => _markers.values.toSet();
  bool get isLoading => _isLoading;
  String? get error => _error;
  Cafe? get selectedCafe => _selectedCafe;
  LatLng get surabayaCenter => _locationService.surabayaCenter;

  CafeProvider() {
    _initLocationService();
    _loadCustomMarkerIcon();
  }

  Future<void> _initLocationService() async {
    try {
      final initialized = await _locationService.init();
      if (initialized) {
        _locationService.startLocationUpdates();
        // Listen to location updates
        _locationService.positionStream.listen((position) {
          // Update cafe distances when location changes
          _updateCafeDistances();
        });
      }
    } catch (e) {
      log('Error initializing location service: $e');
    }
  }

  Future<void> _loadCustomMarkerIcon() async {
    try {
      // Try to load custom marker icon from assets
      _cafeMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/cafe_marker.png',
      );
    } catch (e) {
      log('Error loading custom marker icon: $e');
      // Fallback to default marker with custom hue
      _cafeMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  void selectCafe(String cafeId) {
    if (cafeId.isEmpty) {
      _selectedCafe = null;
    } else {
      _selectedCafe = _cafes.firstWhere(
            (cafe) => cafe.id == cafeId,
        orElse: () => null as Cafe,
      );
    }
    notifyListeners();
  }

  Future<void> loadCafes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cafes = await _cafeService.getCafes();
      _updateCafeDistances(); // Calculate distances based on current location
      await _createMarkers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load cafes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateCafeDistances() {
    final currentPosition = _locationService.currentPosition;
    if (currentPosition == null || _cafes.isEmpty) return;

    for (var i = 0; i < _cafes.length; i++) {
      final cafe = _cafes[i];
      final distance = _locationService.calculateDistance(
        LatLng(currentPosition.latitude, currentPosition.longitude),
        LatLng(cafe.latitude, cafe.longitude),
      );

      // Convert to kilometers with 1 decimal place
      final distanceInKm = distance / 1000;

      // Create a new cafe object with updated distance
      _cafes[i] = Cafe(
        id: cafe.id,
        name: cafe.name,
        address: cafe.address,
        description: cafe.description,
        imageUrl: cafe.imageUrl,
        latitude: cafe.latitude,
        longitude: cafe.longitude,
        rating: cafe.rating,
        isOpen: cafe.isOpen,
        distance: distanceInKm,
        specialties: cafe.specialties,
      );
    }

    // Sort cafes by distance
    _cafes.sort((a, b) => a.distance.compareTo(b.distance));

    // Update marker info windows with new distances
    _updateMarkerInfoWindows();

    notifyListeners();
  }

  void _updateMarkerInfoWindows() {
    for (var cafe in _cafes) {
      if (_markers.containsKey(cafe.id)) {
        final existingMarker = _markers[cafe.id]!;
        _markers[cafe.id] = existingMarker.copyWith(
          infoWindowParam: InfoWindow(
            title: cafe.name,
            snippet: '${cafe.rating} ⭐ • ${cafe.distance.toStringAsFixed(1)} km',
          ),
        );
      }
    }
  }

  Future<void> _createMarkers() async {
    _markers = {};

    // Use custom marker icon if available, otherwise use default
    final markerIcon = _cafeMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);

    for (var cafe in _cafes) {
      final marker = Marker(
        markerId: MarkerId(cafe.id),
        position: LatLng(cafe.latitude, cafe.longitude),
        infoWindow: InfoWindow(
          title: cafe.name,
          snippet: '${cafe.rating} ⭐ • ${cafe.distance.toStringAsFixed(1)} km',
        ),
        icon: markerIcon,
        onTap: () {
          selectCafe(cafe.id);
        },
      );

      _markers[cafe.id] = marker;
    }
  }

  Cafe? getCafeById(String id) {
    try {
      return _cafes.firstWhere((cafe) => cafe.id == id);
    } catch (e) {
      return null;
    }
  }

  // Method to get user's current position
  LatLng? get userLocation {
    final position = _locationService.currentPosition;
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
    return null;
  }

  // Check if location permission is granted
  Future<bool> checkLocationPermission() {
    return _locationService.checkPermission();
  }

  // Open location settings
  Future<bool> openLocationSettings() {
    return _locationService.openLocationSettings();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
