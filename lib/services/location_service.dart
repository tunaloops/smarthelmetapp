import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services are disabled.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception("Location permission denied.");
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions permanently denied.");
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}