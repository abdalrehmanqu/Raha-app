import 'package:flutter_dotenv/flutter_dotenv.dart';

// Configuration values for Raha Oasis.
class AppConfig {
  // Safe access to env with fallback; prevents NotInitializedError on hot restart.
  static String _env(String key, String placeholder) {
    if (!dotenv.isInitialized) return placeholder;
    return dotenv.env[key] ?? placeholder;
  }

  static String get supabaseUrl =>
      _env('SUPABASE_URL', 'YOUR_SUPABASE_URL_HERE');

  static String get supabaseAnonKey =>
      _env('SUPABASE_ANON_KEY', 'YOUR_SUPABASE_ANON_KEY_HERE');

  // Optional: required only if you want to display Google Maps.
  // Add your key to AndroidManifest.xml and AppDelegate/SceneDelegate on iOS.
  static String get googleMapsApiKey =>
      _env('GOOGLE_MAPS_API_KEY', 'YOUR_GOOGLE_MAPS_API_KEY_HERE');

  // Flip this to true once you have configured the Google Maps key
  // on each platform to enable the embedded map.
  static bool get enableGoogleMaps =>
      _env('ENABLE_GOOGLE_MAPS', 'false').toLowerCase() == 'true';

  static bool get hasGoogleMapsKey =>
      googleMapsApiKey.isNotEmpty &&
      !googleMapsApiKey.contains('YOUR_GOOGLE_MAPS_API_KEY_HERE');

  // Quick validity check to avoid white screens when keys are missing.
  static bool get isConfigured =>
      supabaseUrl.startsWith('http') &&
      !supabaseUrl.contains('YOUR_SUPABASE_URL_HERE') &&
      !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY_HERE');
}
