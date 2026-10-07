abstract final class AppConstants {
  static const appName = 'SehatKu';
  static const hospitalName = 'SehatKu Medical Center';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com/v1',
  );
}
