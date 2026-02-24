import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/train_provider.dart';
import 'providers/coach_provider.dart';
import 'providers/sos_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/station_alert_provider.dart';
import 'providers/lost_found_provider.dart';
import 'providers/medical_profile_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/search_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/station_alert_screen.dart';
import 'screens/lost_found_screen.dart';
import 'screens/medical_profile_screen.dart';
import 'services/notification_service.dart';

void main() {
  runApp(const TrainAssistApp());
}

// Global navigator key so we can show dialogs from providers/timers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TrainAssistApp extends StatelessWidget {
  const TrainAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TrainProvider()),
        ChangeNotifierProvider(create: (_) => CoachProvider()),
        ChangeNotifierProvider(create: (_) => SOSProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProvider(create: (_) => StationAlertProvider()),
        ChangeNotifierProvider(create: (_) => LostFoundProvider()),
        ChangeNotifierProvider(create: (_) => MedicalProfileProvider()),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attach a one-time listener for station alert trigger messages
    // so popups appear globally regardless of which screen is open
    final alertProv = context.read<StationAlertProvider>();
    alertProv.addListener(_onAlertTriggered);
  }

  void _onAlertTriggered() {
    final alertProv = context.read<StationAlertProvider>();
    final msg = alertProv.triggerMessage;
    if (msg == null) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.red[50],
          title: const Row(children: [
            Icon(Icons.notifications_active, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Flexible(
              child: Text('STATION ALERT',
                  style: TextStyle(color: Colors.red)),
            ),
          ]),
          content: Text(msg,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          actions: [
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                alertProv.clearTriggerMessage();
                Navigator.pop(navigatorKey.currentContext!);
              },
              child: const Text("OK, I'm Awake!",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    context.read<StationAlertProvider>().removeListener(_onAlertTriggered);
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Initialize notification channel
    await NotificationService().init();
    // Load saved user name
    await Provider.of<UserProvider>(context, listen: false).loadUserName();
    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Train Assist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Primary color scheme
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[700],
        
        // AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        // ElevatedButton theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // Card theme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        
        // Use Material 3
        useMaterial3: true,
      ),
      
      // home uses Consumer to route based on login state
      home: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return userProvider.isUserSet
              ? const SearchScreen()
              : const LoginScreen();
        },
      ),

      // Named routes for in-app navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/search': (context) => const SearchScreen(),
        '/sos': (context) => const SOSScreen(),
        '/station-alert': (context) => const StationAlertScreen(),
        '/lost-found': (context) => const LostFoundScreen(),
        '/medical-profile': (context) => const MedicalProfileScreen(),
      },
    );
  }
}
