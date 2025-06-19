import 'dart:developer';
import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  // Open Google Maps with the given location
  static Future<bool> openMapsWithLocation({
    required double latitude,
    required double longitude,
    required String title,
  }) async {
    final googleMapsUrl = Uri.encodeFull(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$title'
    );

    try {
      final uri = Uri.parse(googleMapsUrl);
      final canLaunchResult = await canLaunchUrl(uri);

      if (canLaunchResult) {
        log('📍 [MapsLauncher] Opening maps with URL: $googleMapsUrl');
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        log('⚠️ [MapsLauncher] Could not launch maps URL');
        return false;
      }
    } catch (e) {
      log('❌ [MapsLauncher] Error opening maps: $e');
      return false;
    }
  }

  // Open directions to a location
  static Future<bool> openDirections({
    required double latitude,
    required double longitude,
    required String title,
  }) async {
    final googleDirectionsUrl = Uri.encodeFull(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_place_id=$title'
    );

    try {
      final uri = Uri.parse(googleDirectionsUrl);
      final canLaunchResult = await canLaunchUrl(uri);

      if (canLaunchResult) {
        log('📍 [MapsLauncher] Opening directions with URL: $googleDirectionsUrl');
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        log('⚠️ [MapsLauncher] Could not launch directions URL');
        return false;
      }
    } catch (e) {
      log('❌ [MapsLauncher] Error opening directions: $e');
      return false;
    }
  }
}
