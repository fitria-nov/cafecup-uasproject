import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Position stream controller
  final StreamController<Position> _positionStreamController = StreamController<Position>.broadcast();
  Stream<Position> get positionStream => _positionStreamController.stream;

  // Properties
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isServiceRunning = false;

  // Default Surabaya center
  final LatLng surabayaCenter = const LatLng(-7.2575, 112.7521);

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isServiceRunning => _isServiceRunning;

  // Initialize the location service
  Future<bool> init() async {
    log('📍 [LocationService] Initializing location service');
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('⚠️ [LocationService] Location services are disabled');
        return false;
      }

      // Check for location permission
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        log('📍 [LocationService] Requesting location permission');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log('⚠️ [LocationService] Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log('⚠️ [LocationService] Location permissions are permanently denied');
        return false;
      }

      // Get initial position
      log('📍 [LocationService] Getting current position');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      log('📍 [LocationService] Current position: $_currentPosition');

      // Forward the position to the stream
      if (_currentPosition != null) {
        _positionStreamController.add(_currentPosition!);
      }

      _isServiceRunning = true;
      log('✅ [LocationService] Location service initialized');
      return true;
    } catch (e) {
      log('❌ [LocationService] Error initializing location service: $e');
      return false;
    }
  }

  // Start listening to location updates
  Future<bool> startLocationUpdates() async {
    if (_isServiceRunning && _positionStreamSubscription != null) {
      log('⚠️ [LocationService] Location updates already running');
      return true;
    }

    try {
      // Begin position stream with specific settings
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
            (Position position) {
          _currentPosition = position;
          _positionStreamController.add(position);
          log('📍 [LocationService] Position update: $position');
        },
        onError: (e) {
          log('⚠️ [LocationService] Error getting location updates: $e');
        },
      );

      log('✅ [LocationService] Started location updates');
      _isServiceRunning = true;
      return true;
    } catch (e) {
      log('❌ [LocationService] Failed to start location updates: $e');
      _isServiceRunning = false;
      return false;
    }
  }

  // Stop listening to location updates
  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isServiceRunning = false;
    log('🛑 [LocationService] Stopped location updates');
  }

  // Get the last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      log('📍 [LocationService] Last known position: $position');
      return position;
    } catch (e) {
      log('⚠️ [LocationService] Error getting last known position: $e');
      return null;
    }
  }

  // Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Check if location permission is granted
  Future<bool> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Ask user to open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // Dispose resources
  void dispose() {
    stopLocationUpdates();
    _positionStreamController.close();
    log('🧹 [LocationService] Resources disposed');
  }
}