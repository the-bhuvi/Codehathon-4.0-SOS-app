import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safe_alert/theme/app_theme.dart';
import 'package:safe_alert/screens/home/home_screen.dart';
import 'package:safe_alert/screens/history/history_screen.dart';
import 'package:safe_alert/screens/settings/settings_screen.dart';
import 'package:safe_alert/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Credentials are injected at build time via --dart-define.
  // Run with:  flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=sb_...
  // Or create a dart_defines/app.env file and use:  flutter run --dart-define-from-file=dart_defines/app.env
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL is not set. Pass it via --dart-define=SUPABASE_URL=...');
  assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY is not set. Pass it via --dart-define=SUPABASE_ANON_KEY=...');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Load saved server URL and apply to ApiService on startup
  final prefs = await SharedPreferences.getInstance();
  final savedUrl = prefs.getString('server_url');

  runApp(ProviderScope(
    overrides: [],
    child: SafeAlertApp(savedServerUrl: savedUrl),
  ));
}

class SafeAlertApp extends ConsumerStatefulWidget {
  final String? savedServerUrl;
  const SafeAlertApp({super.key, this.savedServerUrl});

  @override
  ConsumerState<SafeAlertApp> createState() => _SafeAlertAppState();
}

class _SafeAlertAppState extends ConsumerState<SafeAlertApp> {
  @override
  void initState() {
    super.initState();
    // Apply saved server URL to ApiService on startup
    if (widget.savedServerUrl != null && widget.savedServerUrl!.isNotEmpty) {
      Future.microtask(() {
        ref.read(apiServiceProvider).updateBaseUrl(widget.savedServerUrl!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeAlert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: Colors.red.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.home, color: Colors.redAccent),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.history, color: Colors.redAccent),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.settings, color: Colors.redAccent),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
