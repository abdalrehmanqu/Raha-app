import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:raha/config/app_config.dart';
import 'package:raha/config/app_theme.dart';
import 'package:raha/config/routes.dart';
import 'package:raha/models/pod.dart';
import 'package:raha/screens/auth/sign_in_screen.dart';
import 'package:raha/screens/auth/sign_up_screen.dart';
import 'package:raha/screens/home/main_shell.dart';
import 'package:raha/screens/pods/pod_details_screen.dart';
import 'package:raha/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env if available; falls back to placeholder values in AppConfig.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Keep defaults if .env is missing during quick demos.
  }
  if (!AppConfig.isConfigured) {
    runApp(const ConfigErrorApp(
      message:
          'Supabase keys are missing. Create a .env file from .env.example and restart.',
    ));
    return;
  }

  try {
    // Initialize Supabase (replace placeholder keys in app_config.dart or .env).
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    runApp(const ProviderScope(child: RahaApp()));
  } catch (e) {
    runApp(ConfigErrorApp(
      message:
          'Supabase failed to initialize. Verify SUPABASE_URL and SUPABASE_ANON_KEY.\n$e',
    ));
  }
}

class RahaApp extends ConsumerWidget {
  const RahaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Raha Oasis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.signIn: (_) => const SignInScreen(),
        AppRoutes.signUp: (_) => const SignUpScreen(),
        AppRoutes.home: (_) => const MainShell(),
      },
      // Handle routes with arguments.
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.podDetails) {
          final pod = settings.arguments as Pod;
          return MaterialPageRoute(
            builder: (_) => const PodDetailsScreen(),
            settings: RouteSettings(arguments: pod),
          );
        }
        return null;
      },
    );
  }
}

// Lightweight fallback UI when configuration is missing to avoid a blank screen.
class ConfigErrorApp extends StatelessWidget {
  final String message;
  const ConfigErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF4F0EA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 64, color: Colors.teal),
                const SizedBox(height: 16),
                const Text('Raha Oasis setup needed',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*
Quick README for Raha Oasis (Flutter + Supabase)
------------------------------------------------
1) Configure keys:
   - Copy .env.example to .env and set SUPABASE_URL / SUPABASE_ANON_KEY.
   - Optional: set GOOGLE_MAPS_API_KEY and ENABLE_GOOGLE_MAPS=true, and add the
     platform-specific map key entries (AndroidManifest/iOS AppDelegate).
   - AppConfig also exposes placeholders if .env is missing.

2) Run the app:
   flutter pub get
   flutter run

3) Supabase tables (run in Supabase SQL editor):
   create table profiles (
     id uuid primary key references auth.users on delete cascade,
     full_name text,
     email text,
     created_at timestamp with time zone default now()
   );
   create table pods (
     id bigint generated always as identity primary key,
     name text,
     description text,
     latitude double precision,
     longitude double precision,
     terminal text,
     is_available boolean default true,
     pod_type text default 'normal',
     has_shower boolean default false,
     created_at timestamp with time zone default now()
   );
   create table packages (
     id bigint generated always as identity primary key,
     name text,
     duration_minutes integer,
     price_qr numeric,
     description text,
     created_at timestamp with time zone default now()
   );
create table bookings (
  id bigint generated always as identity primary key,
  user_id uuid references profiles(id) on delete cascade,
  pod_id bigint references pods(id),
  package_id bigint references packages(id),
  start_time timestamptz,
  end_time timestamptz,
  status text,
  shower_requested boolean default false,
  shower_price_qr numeric default 0,
  created_at timestamptz default now()
);

   -- Seed pods
   insert into pods (name, description, latitude, longitude, terminal, is_available, pod_type, has_shower) values
   ('Raha Oasis Pod A1', 'Quiet pod near gates A', 25.2731, 51.6089, '1', true, 'normal', true),
   ('Raha Oasis Pod B2', 'VIP pod close to duty free', 25.2685, 51.6112, '2', true, 'vip', true),
   ('Raha Oasis Pod C3', 'Family-friendly pod', 25.2659, 51.6145, '3', false, 'family', false);

   -- Seed packages
   insert into packages (name, duration_minutes, price_qr, description) values
   ('Power Nap', 60, 80, 'Refresh quickly between flights'),
   ('Transit Rest', 180, 180, 'Unwind during your layover'),
   ('Overnight Stay', 480, 400, 'Full night of rest in privacy');

4) Demo flow to test:
   - Sign up with email + password (creates a profile row).
   - Sign in; home screen fetches pods and shows distance (if location permitted).
   - Tap a pod, pick a package and time, confirm booking (row added to bookings).
   - Open "Bookings" tab, view details, extend active bookings by minutes or package.
*/
