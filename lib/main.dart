import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:rahisisha/providers/auth_provider.dart';
import 'package:rahisisha/providers/business_provider.dart';
import 'package:rahisisha/providers/inventory_provider.dart';
import 'package:rahisisha/providers/records_provider.dart';
import 'package:rahisisha/providers/reports_provider.dart';
import 'package:rahisisha/providers/notes_provider.dart';
import 'package:rahisisha/screens/login_screen.dart';
import 'package:rahisisha/screens/main_navigation_screen.dart';
import 'package:rahisisha/utils/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rahisisha/models/business_record.dart';
import 'package:rahisisha/models/inventory_item.dart';
import 'package:rahisisha/models/note.dart';
import 'package:rahisisha/models/customer.dart';
import 'package:rahisisha/providers/customers_provider.dart';
import 'package:rahisisha/services/api_service.dart';
import 'package:rahisisha/services/database_service.dart';
import 'package:rahisisha/providers/notifications_provider.dart';
import 'package:rahisisha/repositories/business_repository.dart';
import 'package:rahisisha/repositories/customer_repository.dart';
import 'package:rahisisha/screens/splash_screen.dart';
import 'package:rahisisha/services/sync_service.dart';
import 'package:rahisisha/utils/app_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import 'package:flutter/foundation.dart'; // For kIsWeb

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final connectivity = Connectivity();
  
  BusinessRepository businessRepository;
  CustomerRepository customerRepository;
  RecordsProvider recordsProvider;
  InventoryProvider inventoryProvider;
  NotesProvider notesProvider;
  CustomersProvider customersProvider;

  if (kIsWeb) {
    // Web-specific initialization (no offline support)
    businessRepository = BusinessRepository(apiService, null, connectivity);
    customerRepository = CustomerRepository(apiService, null, connectivity);
    recordsProvider = RecordsProvider(businessRepository);
    inventoryProvider = InventoryProvider(businessRepository);
    notesProvider = NotesProvider(apiService);
    customersProvider = CustomersProvider(customerRepository);
  } else {
    // Mobile-specific initialization (with offline support)
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(BusinessRecordAdapter());
    Hive.registerAdapter(InventoryItemAdapter());
    Hive.registerAdapter(CustomerAdapter());

    await Hive.openBox<Note>('notes');
    await Hive.openBox<BusinessRecord>('business_records');
    await Hive.openBox<InventoryItem>('inventory_items');
    await Hive.openBox<Customer>('customers');
    await Hive.openBox<BusinessRecord>('sync_queue');
    await Hive.openBox<InventoryItem>('inventory_sync_queue');
    await Hive.openBox<Note>('notes_sync_queue');

    await DatabaseService.instance.initialize();
    final databaseService = DatabaseService.instance;

    businessRepository = BusinessRepository(apiService, databaseService, connectivity);
    customerRepository = CustomerRepository(apiService, databaseService, connectivity);
    recordsProvider = RecordsProvider(businessRepository);
    inventoryProvider = InventoryProvider(businessRepository);
    notesProvider = NotesProvider(apiService);
    customersProvider = CustomersProvider(customerRepository);

    final syncService = SyncService(apiService, databaseService, recordsProvider, inventoryProvider, notesProvider, customersProvider);
    recordsProvider.setSyncService(syncService);
    inventoryProvider.setSyncService(syncService);
    notesProvider.setSyncService(syncService);
    syncService.start();
  }

  runApp(MyApp(
    businessRepository: businessRepository,
    recordsProvider: recordsProvider,
    inventoryProvider: inventoryProvider,
    notesProvider: notesProvider,
    customersProvider: customersProvider,
  ));
}

class MyApp extends StatelessWidget {
  final BusinessRepository businessRepository;
  final RecordsProvider recordsProvider;
  final InventoryProvider inventoryProvider;
  final NotesProvider notesProvider;
  final CustomersProvider customersProvider;

  const MyApp({Key? key, required this.businessRepository, required this.recordsProvider, required this.inventoryProvider, required this.notesProvider, required this.customersProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider.value(value: inventoryProvider),
        ChangeNotifierProvider.value(value: recordsProvider),
        ChangeNotifierProvider.value(value: notesProvider),
        ChangeNotifierProxyProvider<RecordsProvider, ReportsProvider>(
          create: (context) => ReportsProvider(),
          update: (context, recordsProvider, reportsProvider) =>
              reportsProvider!..update(recordsProvider),
        ),
        ChangeNotifierProvider.value(value: customersProvider),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: MaterialApp(
        title: 'Bizmax App',
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('sw', ''), // Swahili
        ],
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.poppinsTextTheme(),
          fontFamily: 'YourFont', // Optional: for custom font
        ),
        navigatorKey: AppUtils.globalNavigatorKey,
        scaffoldMessengerKey: AppUtils.scaffoldMessengerKey, // Add this line
        locale: const Locale('sw', ''), // Force Swahili for debugging
        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Handle the root route with authentication check
          if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (context) => const RootSplashGate(),
            );
          }

          // Handle other routes from AppRoutes

          final routeBuilder = AppRoutes.routes[settings.name];

          if (routeBuilder != null) {
            return MaterialPageRoute(
              builder: routeBuilder,
              settings: settings,
            );
          }

          // Fallback to AuthWrapper for unknown routes

          return MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          );
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking authentication

        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show login screen if not authenticated

        if (!authProvider.isAuthenticated) {
          return const LoginScreen(key: ValueKey('LoginScreen'));
        }

        // Show main app if authenticated

        if (authProvider.isAuthenticated) {
          // Load inventory data after successful authentication
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<InventoryProvider>(context, listen: false).loadInventory();
            Provider.of<CustomersProvider>(context, listen: false).loadCustomers();
          });
          return const MainNavigationScreen();
        }

        return const SizedBox.shrink(); // Fallback to ensure a widget is always returned
      },
    );
  }
}

class RootSplashGate extends StatefulWidget {
  const RootSplashGate({Key? key}) : super(key: key);

  @override
  State<RootSplashGate> createState() => _RootSplashGateState();
}

class _RootSplashGateState extends State<RootSplashGate> {
  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // Immediately go to AuthWrapper on web

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
          );
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/blue.png', width: 100, height: 100), // Your app logo
              SizedBox(height: 20),
              CircularProgressIndicator(),
              SizedBox(height: 10),
            ],
          ),
        ),
      );
    }

    return const SplashScreen();
  }
}
