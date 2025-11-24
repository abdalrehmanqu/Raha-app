import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_detail.dart';
import '../models/pod.dart';
import '../models/raha_package.dart';

class BookingService {
  final SupabaseClient client;
  BookingService(this.client);

  // Fetch pods from Supabase.
  Future<List<Pod>> fetchPods() async {
    final response = await client.from('pods').select().order('name');
    return (response as List<dynamic>)
        .map((item) => Pod.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Fetch available packages.
  Future<List<RahaPackage>> fetchPackages() async {
    final response = await client.from('packages').select().order('price_qr');
    return (response as List<dynamic>)
        .map((item) => RahaPackage.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Fetch bookings for the current user with pod and package joined.
  Future<List<BookingDetail>> fetchBookings(String userId) async {
    final response = await client
        .from('bookings')
        .select(
            'id, start_time, end_time, status, created_at, pod:pods(*), package:packages(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => BookingDetail.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Insert a new booking row.
  Future<void> createBooking({
    required String userId,
    required Pod pod,
    required RahaPackage package,
    required DateTime startTime,
    bool showerRequested = false,
    num showerPrice = 0,
    num? pricePaid,
  }) async {
    final endTime = startTime.add(Duration(minutes: package.durationMinutes));

    final payload = {
      'user_id': userId,
      'pod_id': pod.id,
      'package_id': package.id,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'status': 'confirmed',
    };

    // Try to persist shower metadata if the columns exist.
    final showerPayload = {
      ...payload,
      'shower_requested': showerRequested,
      'shower_price_qr': showerPrice,
      if (pricePaid != null) 'price_qr': pricePaid,
    };

    try {
      await client.from('bookings').insert(showerPayload);
    } catch (_) {
      // Fallback if columns are not present on the table.
      await client.from('bookings').insert(payload);
    }
  }

  // Demo extension: updates end_time and optionally switches to another package.
  Future<void> extendBooking({
    required dynamic bookingId,
    required DateTime currentEnd,
    required Duration extension,
    RahaPackage? extensionPackage,
  }) async {
    final newEnd = currentEnd.add(extension);

    // You can also update price_qr or store an audit trail in another table.
    final updateData = {
      'end_time': newEnd.toUtc().toIso8601String(),
    };

    if (extensionPackage != null) {
      updateData['package_id'] = extensionPackage.id;
    }

    await client.from('bookings').update(updateData).eq('id', bookingId);
  }

  // Update booking status (check-in, check-out, cancel).
  Future<void> updateStatus({
    required dynamic bookingId,
    required String status,
  }) async {
    await client.from('bookings').update({'status': status}).eq('id', bookingId);
  }
}
