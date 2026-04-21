import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:greenvolt/providers/theme_notifier.dart';
import 'package:greenvolt/providers/zone_provider.dart';
import 'package:greenvolt/screens/energy_control.dart';
import 'package:greenvolt/screens/weather.dart';
import 'package:greenvolt/screens/zones_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_form.dart';
import 'screens/register_form.dart';
import 'screens/home.dart';
import 'screens/battery.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD2_QPWqZ8dwF0427WbFEzbL0wEB5wHq7Y",
        appId: "1:532993898377:web:40342715409f5b0bf95358",
        messagingSenderId: "532993898377",
        projectId: "energymanagementsystem-15dd9",
        databaseURL:
            "https://energymanagementsystem-15dd9-default-rtdb.firebaseio.com",
        storageBucket:
            "energymanagementsystem-15dd9.firebasestorage.app",
      ),
    );
  } catch (e) {
    return;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => ZoneProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    ThemeData buildTheme(Brightness brightness) {
      final dark = brightness == Brightness.dark;
      final base = ColorScheme.fromSeed(
        seedColor: const Color(0xFF00C853),
        brightness: brightness,
      );
      return ThemeData(
        brightness: brightness,
        colorScheme: base,
        scaffoldBackgroundColor:
            dark ? const Color(0xFF0A1410) : const Color(0xFFF3F8F4),
        cardColor: dark ? const Color(0xFF111D16) : Colors.white,
        dialogTheme: DialogThemeData(
          backgroundColor: dark ? const Color(0xFF111D16) : Colors.white,
        ),
        textTheme: GoogleFonts.dmSansTextTheme().apply(
          bodyColor:
              dark ? const Color(0xFFDFF0E8) : const Color(0xFF0D1F15),
          displayColor:
              dark ? const Color(0xFFDFF0E8) : const Color(0xFF0D1F15),
        ),
        useMaterial3: true,
      );
    }

    return MaterialApp(
      title: 'EnerCamp',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.mode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login':   (_) => const LoginScreen(),
        '/signup':  (_) => RegisterScreen(),
        '/home':    (_) => const HomePage(),
        '/zones':   (_) => const ZonesScreen(),
        '/control': (_) => const EnergyControlPage(),
        '/weather': (_) => WeatherScreen(),
        '/battery': (_) => const BatteryPage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: const Color(0xFF0D2318),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00C853).withValues(alpha: 0.15),
                        border: Border.all(
                            color: const Color(0xFF00C853).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: Color(0xFF00C853), size: 40),
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                        color: Color(0xFF00C853), strokeWidth: 2),
                  ],
                ),
              ),
            );
          }
          if (snap.hasData) return const HomePage();
          return const WelcomeScreen();
        },
      ),
    );
  }
}
