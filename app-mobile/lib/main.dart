import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'providers/adhan_settings_provider.dart';
import 'providers/masjid_provider.dart';
import 'services/adhan_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/language_onboarding_screen.dart';
import 'screens/onboarding/location_onboarding_screen.dart';
import 'screens/onboarding/alarm_onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/notifications_settings_screen.dart';
import 'screens/profile/location_settings_screen.dart';

// ── ThemeMode + text-scale notifier ──────────────────────────────────────────
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode      = ThemeMode.dark;
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

// ── App entry point ───────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error handler — prevents silent crashes.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}\n${details.stack}');
  };

  // ── Firebase (must succeed before app starts) ──────────────────────────────
  String? firebaseError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    firebaseError = e.toString();
    debugPrint('[main] Firebase init failed: $e');
  }

  // ── Stripe (native-only, skip if no valid key configured) ─────────────────
  if (!kIsWeb && firebaseError == null) {
    // Replace with a real key via --dart-define=STRIPE_KEY=pk_live_...
    const stripeKey = String.fromEnvironment('STRIPE_KEY');
    if (stripeKey.isNotEmpty) {
      try {
        Stripe.publishableKey = stripeKey;
        await Stripe.instance.applySettings();
      } catch (e) {
        debugPrint('[main] Stripe init failed: $e');
      }
    }
  }

  // ── Background services (only when Firebase is healthy) ───────────────────
  if (firebaseError == null) {
    AdhanService.instance.init().ignore();
    if (!kIsWeb) NotificationService.instance.init().ignore();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => DawahProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => AdhanSettingsProvider()),
        ChangeNotifierProxyProvider2<LocationProvider, AdhanSettingsProvider, PrayerProvider>(
          create: (_) => PrayerProvider(),
          update: (_, loc, adhanSettings, prayer) {
            if (loc.hasLocation) {
              prayer?.updateCoordinates(loc.lat!, loc.lng!);
            }
            prayer?.updateSettings(adhanSettings.settings);
            return prayer!;
          },
        ),
        ChangeNotifierProvider(create: (_) => MasjidProvider()),
      ],
      child: SunnahGrandeurApp(firebaseError: firebaseError),
    ),
  );
}

// ── Root app widget ───────────────────────────────────────────────────────────
class SunnahGrandeurApp extends StatelessWidget {
  const SunnahGrandeurApp({super.key, this.firebaseError});
  final String? firebaseError;

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
      builder: (context, child) => Directionality(
        textDirection: lang.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(themeNotifier.textScale),
          ),
          child: child!,
        ),
      ),
      home: firebaseError != null
          ? _FirebaseErrorScreen(error: firebaseError!)
          : const SplashScreen(),
      routes: {
        '/welcome':           (_) => const WelcomeScreen(),
        '/onboard/language':  (_) => const LanguageOnboardingScreen(),
        '/onboard/location':  (_) => const LocationOnboardingScreen(),
        '/onboard/alarms':    (_) => const AlarmOnboardingScreen(),
        '/login':             (_) => const LoginScreen(),
        '/register':          (_) => const RegisterScreen(),
        '/main':              (_) => const ShellScreen(),
        '/settings/notifications': (_) => const NotificationsSettingsScreen(),
        '/settings/location':      (_) => const LocationSettingsScreen(),
      },
    );
  }
}

// ── Landing / auth gate ───────────────────────────────────────────────────────
//
// Routing logic:
//   • Loading (≤5 s)      → gold spinner
//   • Loading (>5 s)      → force WelcomeScreen (prevents stuck splash)
//   • Not signed in       → WelcomeScreen  (no forced registration)
//   • Signed in (or guest)→ ShellScreen    (guests see the full app)
//
// Navigation from child screens (WelcomeScreen, LoginScreen, RegisterScreen):
//   Use Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false)
//   after successful auth to clear the stack and land on ShellScreen cleanly.
//
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _forceShow = false; // safety unlock after 5 s

  @override
  void initState() {
    super.initState();
    // Safety valve: if Firebase auth hasn't resolved in 5 seconds,
    // stop showing the spinner and let the user interact.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_forceShow) setState(() => _forceShow = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading && !_forceShow) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0F),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC8A55A)),
          ),
        ),
      );
    }

    // Guest users (isAnonymous) are welcome — they can explore freely.
    // Only unauthenticated (null) users are directed to the welcome screen.
    if (!auth.isSignedIn) {
      return const WelcomeScreen();
    }

    return const ShellScreen();
  }
}

// ── Blocking Firebase error screen ───────────────────────────────────────────
class _FirebaseErrorScreen extends StatelessWidget {
  const _FirebaseErrorScreen({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFE53935), size: 48),
              const SizedBox(height: 24),
              Text(
                'Initialization Failed',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The app could not connect to Firebase.\nPlease check your internet connection and try again.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2D)),
                ),
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
