import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/discovery_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/interaction_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/search_filter_provider.dart';
import 'services/location_service.dart';
import 'providers/subscription_provider.dart';

import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_profile_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/publish_wizard_screen.dart';
import 'screens/saved_profiles_screen.dart';
import 'screens/interests_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/edit_personal_details_screen.dart';
import 'screens/edit_partner_preferences_screen.dart';
import 'screens/visitors_screen.dart';
import 'screens/static_settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MatrimonyApp());
}

class MatrimonyApp extends StatelessWidget {
  const MatrimonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Auth & Session Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // 2. Discovery Provider (Groom & Bride feeds, swipe actions)
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),
        // 3. Profile Provider (User's own profile and 3-phase publishing wizard)
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        // 4. Interaction Provider (Saved profiles, Interests sent/received, Matches, Visitors)
        ChangeNotifierProvider(create: (_) => InteractionProvider()),
        // 5. Notification Provider (Unread counter & activity notifications)
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        // 6. Search & Filter Provider (Location, age range, religion, community, education)
        ChangeNotifierProvider(create: (_) => SearchFilterProvider()),
        // 7. Location Service for GPS reverse geocoding
        ChangeNotifierProvider(create: (_) => LocationService()),
        // 8. Subscription Provider for Daily Swipe Quota & Unlimited Plan
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MaterialApp(
        title: 'Matrimonyer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // SplashRouter handles session restore before showing any screen
        home: const _SplashRouter(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const MainScreen());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/notifications':
              return MaterialPageRoute(builder: (_) => const NotificationsScreen());
            case '/account-hub':
              return MaterialPageRoute(builder: (_) => const SettingsProfileScreen());
            case '/my-profile':
              return MaterialPageRoute(builder: (_) => const MyProfileScreen());
            case '/edit-personal-details':
              return MaterialPageRoute(builder: (_) => const EditPersonalDetailsScreen());
            case '/edit-partner-preferences':
              return MaterialPageRoute(builder: (_) => const EditPartnerPreferencesScreen());
            case '/publish-wizard':
              return MaterialPageRoute(builder: (_) => const PublishWizardScreen());
            case '/saved-profiles':
              return MaterialPageRoute(builder: (_) => const SavedProfilesScreen());
            case '/interests':
              final tabIndex = (settings.arguments as int?) ?? 0;
              return MaterialPageRoute(builder: (_) => InterestsScreen(initialTabIndex: tabIndex));
            case '/matches':
              return MaterialPageRoute(builder: (_) => const MatchesScreen());
            case '/visitors':
              return MaterialPageRoute(builder: (_) => const VisitorsScreen());
            case '/privacy-settings':
              return MaterialPageRoute(
                builder: (_) => const StaticSettingsScreen(type: SettingsScreenType.privacy),
              );
            case '/notification-settings':
              return MaterialPageRoute(
                builder: (_) => const StaticSettingsScreen(type: SettingsScreenType.notifications),
              );
            case '/help-support':
              return MaterialPageRoute(
                builder: (_) => const StaticSettingsScreen(type: SettingsScreenType.help),
              );
            case '/about-app':
              return MaterialPageRoute(
                builder: (_) => const StaticSettingsScreen(type: SettingsScreenType.about),
              );
            default:
              return MaterialPageRoute(builder: (_) => const MainScreen());
          }
        },
      ),
    );
  }
}

/// Splash Router: restores session from stored JWT, redirects to login or main app.
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final profile = await auth.restoreSession();

    if (!mounted) return;

    if (auth.isLoggedIn) {
      // Seed profile into ProfileProvider
      if (profile != null) {
        context.read<ProfileProvider>().seedProfileFromApi(profile);
      } else {
        context.read<ProfileProvider>().fetchMyProfile();
      }

      // Load discovery and interaction data
      await Future.wait([
        context.read<DiscoveryProvider>().fetchAllProfiles(),
        context.read<InteractionProvider>().fetchAll(),
        context.read<NotificationProvider>().fetchNotifications(),
        context.read<SubscriptionProvider>().fetchStatus(),
      ]);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.burgundy.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.asset(
                    'assets/images/matrimonyer_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/spouse_spotter_icon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('💍', style: TextStyle(fontSize: 44)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Matrimonyer',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.burgundy,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppTheme.burgundy, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
