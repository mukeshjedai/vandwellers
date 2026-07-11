/// Google Maps / Places API configuration.
/// Override at build time: --dart-define=GOOGLE_MAPS_API_KEY=your_key
class GoogleMapsConfig {
  static const apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyCsk61NfeS4NrY4bjRgB-tfOSDU6JldHAA',
  );
}
