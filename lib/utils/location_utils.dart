import 'package:geolocator/geolocator.dart';

/// Returns (latitude, longitude) as strings.
/// Returns ('', '') if permission is denied, location is unavailable, or any error occurs.
Future<(String, String)> fetchLocationCoords() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return ('', '');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return ('', '');
    }
    if (permission == LocationPermission.deniedForever) return ('', '');

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: const Duration(seconds: 8),
    );
    return (position.latitude.toString(), position.longitude.toString());
  } catch (_) {
    return ('', '');
  }
}
