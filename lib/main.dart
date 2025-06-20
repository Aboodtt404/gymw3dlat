import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/supabase_service.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/smart_workout_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'screens/auth/reset_password_screen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Debug print for API keys validation
  final exerciseDbKey = dotenv.env['EXERCISEDB_API_KEY'] ?? 'not found';
  final nutritionixAppId = dotenv.env['NUTRITIONIX_APP_ID'] ?? 'not found';
  final nutritionixApiKey = dotenv.env['NUTRITIONIX_API_KEY'] ?? 'not found';

  if (exerciseDbKey == 'not found') {
    print('WARNING: ExerciseDB API key not found in .env file!');
  } else {
    final maskedKey = exerciseDbKey.length > 8
        ? '${exerciseDbKey.substring(0, 4)}...${exerciseDbKey.substring(exerciseDbKey.length - 4)}'
        : '****';
    print('ExerciseDB API key loaded: $maskedKey');
  }

  if (nutritionixAppId == 'not found' || nutritionixApiKey == 'not found') {
    print('WARNING: Nutritionix API credentials not found in .env file!');
    print(
        'Smart meal recommendations will not work without Nutritionix API credentials.');
  } else {
    print('Nutritionix API credentials loaded successfully');
  }

  await SupabaseService.initializeSupabase();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _sub = uriLinkStream.listen((Uri? uri) {
        if (uri != null &&
            uri.scheme == 'gymw3dlat' &&
            uri.host == 'reset-password') {
          Navigator.of(navigatorKey.currentContext!).pushNamed(
            '/reset-password',
            arguments: uri.queryParameters,
          );
        }
      });
    } else if (kIsWeb) {
      final uri = Uri.base;
      if (uri.path == '/reset-password') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(navigatorKey.currentContext!).pushNamed(
            '/reset-password',
            arguments: uri.queryParameters,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(widget.prefs)),
        ChangeNotifierProvider(
            create: (_) => UserProvider(SupabaseService.client)),
        ChangeNotifierProvider(create: (_) => SmartWorkoutProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Gym App',
            theme: themeProvider.theme,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
            routes: {
              '/reset-password': (context) => ResetPasswordScreen(),
            },
          );
        },
      ),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupabaseService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && SupabaseService.currentUser != null) {
          // Initialize user data when authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserProvider>().initializeUser();
          });
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
