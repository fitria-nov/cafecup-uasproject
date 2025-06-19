import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/cafe_model.dart';
import '../../utils/app_colors.dart';

class CafeMapScreen extends StatefulWidget {
  final Cafe cafe;

  const CafeMapScreen({super.key, required this.cafe});

  @override
  State<CafeMapScreen> createState() => _CafeMapScreenState();
}

class _CafeMapScreenState extends State<CafeMapScreen> {
  GoogleMapController? _mapController;
  late LatLng _cafePosition;

  @override
  void initState() {
    super.initState();
    _cafePosition = LatLng(widget.cafe.latitude, widget.cafe.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cafe.name),
        backgroundColor: AppColors.surface,
        elevation: 1,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _cafePosition,
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: MarkerId(widget.cafe.id),
            position: _cafePosition,
            infoWindow: InfoWindow(
              title: widget.cafe.name,
              snippet: widget.cafe.address,
            ),
          ),
        },
        onMapCreated: (controller) {
          _mapController = controller;
        },
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        zoomControlsEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _cafePosition, zoom: 16),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.location_pin),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
