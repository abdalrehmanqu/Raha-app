import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raha/config/routes.dart';
import 'package:raha/providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Wait briefly to show the splash and allow Supabase to hydrate the session.
    await Future.delayed(const Duration(milliseconds: 500));
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (!mounted) return;
    if (session == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.signIn);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.nightlight_round, size: 72, color: Color(0xFF2E9C91)),
            SizedBox(height: 16),
            Text('Raha Oasis', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
