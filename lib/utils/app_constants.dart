class AppConstants {
  // App Information
  static const String appName = 'Bizmax';
  static const String appVersion = '1.0.0';
  static const int databaseVersion = 1;
  static const String backupVersion = '1.0';

  // Business Categories
  static const List<String> businessCategories = [
    'Chakula na Vinywaji',
    'Nguo na Vazi',
    'Elektroniki',
    'Nyumba na Bustani',
    'Afya na Urembo',
    'Vitabu na Elimu',
    'Michezo na Burudani',
    'Gari na Usafiri',
    'Huduma za Kiteknolojia',
    'Mingine',
  ];

  // Expense Categories
  static const List<String> expenseCategories = [
    'Kodi na Ada',
    'Umeme na Maji',
    'Kodi ya Nyumba',
    'Usafiri',
    'Matengenezo',
    'Mahitaji ya Ofisi',
    'Matangazo',
    'Mishahara',
    'Bima',
    'Mingine',
  ];

  // Units of Measurement
  static const List<String> units = [
    'Kipande',
    'Kilo',
    'Lita',
    'Mita',
    'Sanduku',
    'Gunia',
    'Debe',
    'Pakiti',
    'Dozi',
    'Mingine',
  ];

  // Currency
  static const String currency = 'TSh';
  static const String currencySymbol = 'TSh ';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Paths
  static const String backupDirectory = 'backups';
  static const String reportsDirectory = 'reports';

  // Validation
  static const int maxDescriptionLength = 200;
  static const int maxNameLength = 100;
  static const double maxAmount = 999999999.99;
  static const int minStockLevel = 0;

  // Colors (Material Design 3)
  static const Map<String, int> primaryColors = {
    'blue': 0xFF1976D2,
    'green': 0xFF388E3C,
    'orange': 0xFFFF9800,
    'red': 0xFFD32F2F,
    'purple': 0xFF7B1FA2,
  };

  // Business Health Thresholds
  static const double lowStockThreshold = 0.2; // 20% of minimum stock
  static const double profitMarginThreshold = 0.15; // 15% profit margin
  static const int daysForHealthCheck = 30;

  // Backup Settings
  static const int autoBackupDays = 7;
  static const int maxBackupFiles = 10;

  // Notification Settings
  static const int lowStockNotificationHour = 9; // 9 AM
  static const int dailyReportNotificationHour = 18; // 6 PM
}
