import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class AuthService {
  final SupabaseClient client;
  AuthService(this.client);

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  // Sign up and create profile row
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    final userId = response.user?.id;
    if (userId != null) {
      await client.from('profiles').insert({
        'id': userId,
        'full_name': fullName,
        'email': email,
      });
    }
    return response;
  }

  Future<void> signOut() => client.auth.signOut();

  Session? currentSession() => client.auth.currentSession;

  Future<Profile?> fetchProfile(String userId) async {
    final result = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (result == null) return null;
    return Profile.fromMap(result);
  }
}
