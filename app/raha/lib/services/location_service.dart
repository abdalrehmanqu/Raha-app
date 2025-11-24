import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium);
  }

  double? distanceInKm(double startLat, double startLng, double endLat, double endLng) {
    try {
      final meters =
          Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
      return meters / 1000;
    } catch (_) {
      return null;
    }
  }
}
