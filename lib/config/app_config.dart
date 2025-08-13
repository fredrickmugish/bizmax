class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fortex.co.tz/api', // Production
  );
  
  static const String appName = 'Rahisisha Business';
  static const String appVersion = '1.0.0';
  
  // API endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String dashboardEndpoint = '/dashboard';
  static const String inventoryEndpoint = '/inventory';
  static const String recordsEndpoint = '/business-records';
  static const String notificationsEndpoint = '/notifications';
  
  // For production, you might want to use:
  // static const String baseUrl = 'https://your-api-domain.com/api';
}
