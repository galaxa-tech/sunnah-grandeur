import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/store_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/media_provider.dart';
import 'providers/dawah_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/location_provider.dart';
import 'providers/language_provider.dart';
import 'services/adhan_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/shell_screen.dart';
import 'screens/onboarding/location_onboarding_screen.dart';
import 'screens/onboarding/alarm_onboarding_screen.dart';
import 'screens/onboarding/language_onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/notifications_settings_screen.dart';
import 'screens/profile/location_settings_screen.dart';

// ── ThemeMode + text-scale notifier ────────────────────────────────────────────
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode      = ThemeMode.light;
  double    _textScale = 1.0;

  ThemeMode get mode      => _mode;
  bool      get isDark    => _mode == ThemeMode.dark;
  double    get textScale => _textScale;

  void toggle() {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setDark(bool dark) {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSystem() {
    _mode = ThemeMode.system;
    notifyListeners();
  }

  void setTextScale(double scale) {
    _textScale = scale.clamp(0.85, 1.35);
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (!kIsWeb) {
      Stripe.publishableKey = 'pk_test_51P9vP0000000000000000000';
      await Stripe.instance.applySettings();
    }
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  AdhanService.instance.init().ignore();
  NotificationService.instance.init().ignore();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => DawahProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProxyProvider<LocationProvider, PrayerProvider>(
          create: (_) => PrayerProvider(),
          update: (_, loc, prayer) {
            if (loc.hasLocation) {
              prayer?.updateCoordinates(loc.lat!, loc.lng!);
            }
            return prayer!;
          },
        ),
      ],
      child: const SunnahGrandeurApp(),
    ),
  );
}

class SunnahGrandeurApp extends StatelessWidget {
  const SunnahGrandeurApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final lang          = context.watch<LanguageProvider>();

    return MaterialApp(
      title: 'Sunnah Grandeur',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.mode,
      theme:     AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: lang.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('bn'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final isRtl = lang.isRtl;
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(themeNotifier.textScale),
            ),
            child: child!,
          ),
        );
      },
      home: const LandingPage(),
      routes: {
        '/onboard/location': (_) => const LocationOnboardingScreen(),
        '/onboard/alarms':   (_) => const AlarmOnboardingScreen(),
        '/login':            (_) => const LoginScreen(),
        '/register':         (_) => const RegisterScreen(),
        '/main':             (_) => const ShellScreen(),
        '/settings/notifications': (_) => const NotificationsSettingsScreen(),
        '/settings/location':      (_) => const LocationSettingsScreen(),
      },
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.firebaseUser == null) {
      return const LanguageOnboardingScreen();
    }

    return const ShellScreen();
  }
}
