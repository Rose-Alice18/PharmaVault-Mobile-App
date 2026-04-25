import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  Position? _position;
  String    _cityName = 'Locating...';
  bool      _loading  = false;
  bool      _denied   = false;

  Position? get position  => _position;
  String    get cityName  => _cityName;
  bool      get isLoading => _loading;
  bool      get isDenied  => _denied;

  Future<void> fetchLocation() async {
    _loading = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _cityName = 'Location off';
        _denied   = true;
        _loading  = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _cityName = 'Accra, Ghana';
        _denied   = true;
        _loading  = false;
        notifyListeners();
        return;
      }

      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final placemarks = await placemarkFromCoordinates(_position!.latitude, _position!.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _cityName = p.locality?.isNotEmpty == true
            ? '${p.locality}, ${p.country}'
            : p.administrativeArea ?? 'Unknown';
      }
    } catch (_) {
      _cityName = 'Accra, Ghana';
    }

    _loading = false;
    notifyListeners();
  }

  /// Distance in km between user and a point. Returns null if no position yet.
  double? distanceTo(double lat, double lng) {
    if (_position == null) return null;
    final meters = Geolocator.distanceBetween(
      _position!.latitude, _position!.longitude, lat, lng,
    );
    return meters / 1000;
  }

  String distanceLabel(double? lat, double? lng) {
    if (lat == null || lng == null) return '';
    final km = distanceTo(lat, lng);
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }
}
