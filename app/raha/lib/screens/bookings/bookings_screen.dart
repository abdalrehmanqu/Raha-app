import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:raha/models/booking_detail.dart';
import 'package:raha/models/raha_package.dart';
import 'package:raha/providers/providers.dart';
import 'package:raha/widgets/booking_card.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  Future<void> _showExtendSheet(
    BuildContext context,
    WidgetRef ref,
    BookingDetail booking,
  ) async {
    final packages = await ref.read(packagesProvider.future);
    if (!context.mounted) return;
    final minutesController =
        TextEditingController(text: booking.package?.durationMinutes.toString() ?? '30');
    RahaPackage? chosenPackage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Extend booking',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<RahaPackage>(
                decoration: const InputDecoration(labelText: 'Add another package'),
                items: packages
                    .map((pkg) => DropdownMenuItem(
                          value: pkg,
                          child: Text('${pkg.name} (+${pkg.durationMinutes} mins, ${pkg.priceQr} QAR)'),
                        ))
                    .toList(),
                onChanged: (value) {
                  chosenPackage = value;
                  if (value != null) {
                    minutesController.text = value.durationMinutes.toString();
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Or custom minutes', suffixText: 'mins'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final mins = int.tryParse(minutesController.text.trim()) ?? 0;
                  if (mins <= 0) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter minutes to extend.')));
                    return;
                  }
                  await ref.read(bookingServiceProvider).extendBooking(
                        bookingId: booking.id,
                        currentEnd: booking.endTime,
                        extension: Duration(minutes: mins),
                        extensionPackage: chosenPackage,
                      );
                  ref.invalidate(bookingsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking updated.')));
                  }
                },
                child: const Text('Save extension'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    Future<void> updateStatus(String status, BookingDetail booking) async {
      await ref
          .read(bookingServiceProvider)
          .updateStatus(bookingId: booking.id, status: status);
      ref.invalidate(bookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Booking $status.')));
      }
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bookingsProvider);
          await ref.read(bookingsProvider.future);
        },
        child: bookingsAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No bookings yet. Book a pod to see it here.')),
                ],
              );
            }
            final now = DateTime.now();
            final upcoming = [...bookings]
              ..sort((a, b) => a.startTime.compareTo(b.startTime));
            final nextBooking = upcoming
                .firstWhere((b) => b.endTime.isAfter(now), orElse: () => bookings.first);
            final confirmedCount =
                bookings.where((b) => b.status == 'confirmed').length;
            final inProgressCount =
                bookings.where((b) => b.status == 'in_progress').length;
            final active = bookings
                .where((b) => b.status == 'confirmed' || b.status == 'in_progress')
                .toList();
            final past = bookings
                .where((b) =>
                    b.status == 'completed' ||
                    b.status == 'cancelled' ||
                    b.status == 'pending')
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE6F4F1), Color(0xFFD2E9E2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your trips',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.check_circle, size: 16),
                            label: Text('Confirmed: $confirmedCount'),
                            backgroundColor: Colors.white,
                          ),
                          Chip(
                            avatar: const Icon(Icons.timer, size: 16),
                            label: Text('In progress: $inProgressCount'),
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Next: ${nextBooking.pod?.name ?? 'Pod'} • ${DateFormat('MMM d, h:mm a').format(nextBooking.startTime)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (active.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Text('Active',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ...active.map((booking) {
                  final isConfirmed = booking.status == 'confirmed';
                  final isInProgress = booking.status == 'in_progress';
                  final canExtend = booking.isActive;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookingCard(
                        booking: booking,
                        onExtend: canExtend
                            ? () => _showExtendSheet(context, ref, booking)
                            : null,
                        onTap: () {
                          final formatter = DateFormat('MMM d, y h:mm a');
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(booking.pod?.name ?? 'Booking'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Package: ${booking.package?.name ?? ''}'),
                                  Text(
                                      'When: ${formatter.format(booking.startTime)} → ${formatter.format(booking.endTime)}'),
                                  Text('Status: ${booking.status}'),
                                  if (booking.pod?.terminal != null)
                                    Text('Terminal: ${booking.pod!.terminal}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        actions: (isConfirmed || isInProgress)
                            ? Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF7F5),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    if (isConfirmed)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          icon: const Icon(Icons.login),
                                          label: const Text('Check in'),
                                          onPressed: () =>
                                              updateStatus('in_progress', booking),
                                        ),
                                      ),
                                    if (isInProgress)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          icon: const Icon(Icons.logout),
                                          label: const Text('Check out'),
                                          onPressed: () =>
                                              updateStatus('completed', booking),
                                        ),
                                      ),
                                    if (isConfirmed) const SizedBox(width: 10),
                                    if (isConfirmed)
                                      TextButton.icon(
                                        icon: const Icon(Icons.cancel_outlined),
                                        label: const Text('Cancel'),
                                        onPressed: () =>
                                            updateStatus('cancelled', booking),
                                      ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    ],
                  );
                }),
                if (past.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Text('History',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ...past.map((booking) {
                  return BookingCard(
                    booking: booking,
                    onTap: () {
                      final formatter = DateFormat('MMM d, y h:mm a');
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(booking.pod?.name ?? 'Booking'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Package: ${booking.package?.name ?? ''}'),
                              Text(
                                  'When: ${formatter.format(booking.startTime)} → ${formatter.format(booking.endTime)}'),
                              Text('Status: ${booking.status}'),
                              if (booking.pod?.terminal != null)
                                Text('Terminal: ${booking.pod!.terminal}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Could not load bookings: $error'),
            ],
          ),
        ),
      ),
    );
  }
}
