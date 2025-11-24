import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_detail.dart';
import '../models/pod.dart';
import '../models/profile.dart';
import '../models/raha_package.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/location_service.dart';

// Shared Supabase client provider
final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

// Services
final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.read(supabaseClientProvider)));
final bookingServiceProvider = Provider<BookingService>(
    (ref) => BookingService(ref.read(supabaseClientProvider)));
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

// Session stream that emits the current session first, then listens to changes.
final sessionProvider = StreamProvider<Session?>((ref) async* {
  final client = ref.read(supabaseClientProvider);
  yield client.auth.currentSession;
  yield* client.auth.onAuthStateChange.map((event) => event.session);
});

// Convenience to access the current user.
final currentUserProvider = Provider<User?>((ref) {
  final session = ref.watch(sessionProvider).valueOrNull;
  return session?.user;
});

// Profile loader
final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(authServiceProvider).fetchProfile(user.id);
});

// Pods + packages
final podsProvider = FutureProvider<List<Pod>>(
    (ref) => ref.read(bookingServiceProvider).fetchPods());
final packagesProvider = FutureProvider<List<RahaPackage>>(
    (ref) => ref.read(bookingServiceProvider).fetchPackages());

// Bookings for the signed-in user
final bookingsProvider = FutureProvider<List<BookingDetail>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(bookingServiceProvider).fetchBookings(user.id);
});

// Location helper
final locationProvider = FutureProvider<Position?>(
    (ref) => ref.read(locationServiceProvider).getCurrentPosition());
