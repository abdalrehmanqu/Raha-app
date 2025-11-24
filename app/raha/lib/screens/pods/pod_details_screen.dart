// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:raha/config/routes.dart';
import 'package:raha/models/pod.dart';
import 'package:raha/models/raha_package.dart';
import 'package:raha/providers/providers.dart';
import 'package:raha/widgets/primary_button.dart';

class PodDetailsScreen extends ConsumerStatefulWidget {
  const PodDetailsScreen({super.key});

  static const routeName = AppRoutes.podDetails;

  @override
  ConsumerState<PodDetailsScreen> createState() => _PodDetailsScreenState();
}

class _PodDetailsScreenState extends ConsumerState<PodDetailsScreen> {
  RahaPackage? _selectedPackage;
  DateTime _selectedStart = DateTime.now().add(const Duration(minutes: 30));
  bool _isSaving = false;
  bool _includeShower = false;

  // Dynamic pricing by pod type; adjusts package price while keeping durations.
  num _adjustedPrice(RahaPackage pkg, Pod pod) {
    switch (pod.type.toLowerCase()) {
      case 'vip':
        return (pkg.priceQr * 1.25).round(); // 25% uplift for VIP lounge comfort
      case 'family':
        return (pkg.priceQr * 1.15).round(); // 15% uplift for extra space/beds
      default:
        return pkg.priceQr;
    }
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: _selectedStart,
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedStart),
    );
    if (pickedTime == null) return;

    if (!mounted) return;
    setState(() {
      _selectedStart = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  DateTime? get _calculatedEnd {
    if (_selectedPackage == null) return null;
    return _selectedStart
        .add(Duration(minutes: _selectedPackage!.durationMinutes));
  }

  bool get _showerIsFree =>
      _selectedPackage != null && _selectedPackage!.durationMinutes >= 240;

  num get _showerPrice => _showerIsFree ? 0 : 50; // 50 QAR under 4h

  Future<void> _book(Pod pod) async {
    if (_selectedPackage == null) {
      _showSnack('Please choose a package first.');
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showSnack('Please sign in first.');
      Navigator.pushReplacementNamed(context, AppRoutes.signIn);
      return;
    }
    final isVip = pod.type.toLowerCase() == 'vip';
    const vipSurchargeQr = 120; // Additional cost for VIP pods (includes shower).
    final packagePrice = _adjustedPrice(_selectedPackage!, pod);
    final includeShower = isVip || (_includeShower && pod.hasShower);
    final showerPrice =
        includeShower ? (isVip ? vipSurchargeQr : _showerPrice) : 0;
    final totalPrice = packagePrice + showerPrice;
    setState(() => _isSaving = true);
    try {
      await ref.read(bookingServiceProvider).createBooking(
            userId: user.id,
            pod: pod,
            package: _selectedPackage!,
            startTime: _selectedStart,
            showerRequested: includeShower,
            showerPrice: showerPrice,
            pricePaid: totalPrice,
          );
      ref.invalidate(bookingsProvider);
      if (!mounted) return;
      _showSnack('Booking confirmed!');
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Could not create booking. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final Pod pod =
        ModalRoute.of(context)!.settings.arguments as Pod? ??
            Pod(
              id: 0,
              name: 'Pod',
              description: '',
              latitude: 0,
              longitude: 0,
              terminal: '',
              isAvailable: false,
              type: 'normal',
              hasShower: false,
            );
    final packagesAsync = ref.watch(packagesProvider);
    final formatter = DateFormat('MMM d, h:mm a');
    final isVip = pod.type.toLowerCase() == 'vip';
    const vipSurchargeQr = 120;

    return Scaffold(
      appBar: AppBar(title: Text(pod.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pod.terminal,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(pod.description),
            const SizedBox(height: 12),
            Chip(
              avatar: Icon(
                pod.isAvailable ? Icons.check_circle : Icons.block,
                color: pod.isAvailable ? Colors.green : Colors.redAccent,
              ),
              label: Text(pod.isAvailable ? 'Available' : 'Not available'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  backgroundColor: Colors.teal.shade50,
                  label: Text('Type: ${pod.type.toUpperCase()}'),
                ),
                Chip(
                  avatar: const Icon(Icons.shower, size: 18),
                  label: Text(
                      pod.hasShower ? 'Shower on site' : 'No shower available'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Packages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            packagesAsync.when(
              data: (packages) {
                return Column(
                  children: packages
                      .map(
                        (pkg) => RadioListTile<RahaPackage>(
                          value: pkg,
                          groupValue: _selectedPackage,
                          onChanged: (value) =>
                              setState(() => _selectedPackage = value),
                          title: Text(pkg.name),
                          subtitle: Text(
                              '${pkg.durationMinutes} mins • ${_adjustedPrice(pkg, pod)} QAR'
                              '${(pod.type.toLowerCase() != 'normal') ? ' (${pod.type} rate)' : ''}'),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () =>
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(),
                  ),
              error: (error, _) =>
                  Text('Could not load packages: $error'),
            ),
            const SizedBox(height: 16),
            const Text('Booking time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              onTap: _pickStart,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.schedule),
              title: Text(formatter.format(_selectedStart)),
              subtitle: _calculatedEnd != null
                  ? Text('Ends ${formatter.format(_calculatedEnd!)}')
                  : const Text('Pick a start time'),
              trailing: const Icon(Icons.edit),
            ),
            if (pod.hasShower) ...[
              const SizedBox(height: 16),
              if (isVip)
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.shower, color: Colors.teal),
                  title: const Text('Shower included (VIP)'),
                  subtitle: Text(
                      'VIP surcharge: $vipSurchargeQr QAR (includes shower access).'),
                )
              else
                ListTile(
                  onTap: () => setState(() => _includeShower = !_includeShower),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: Checkbox(
                    value: _includeShower,
                    onChanged: (value) => setState(() => _includeShower = value ?? false),
                  ),
                  title: const Text('Add shower access'),
                  subtitle: Text(_showerIsFree
                      ? 'Free with stays of 4h or more.'
                      : '50 QAR add-on for stays under 4h.'),
                  trailing: const Icon(Icons.shower),
              ),
            ],
            const SizedBox(height: 24),
            if (_selectedPackage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Summary',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Pod: ${pod.name}'),
                      Text('Package: ${_selectedPackage!.name}'),
                      Text('Start: ${formatter.format(_selectedStart)}'),
                      if (_calculatedEnd != null)
                        Text('End: ${formatter.format(_calculatedEnd!)}'),
                      Text(
                          'Package price: ${_adjustedPrice(_selectedPackage!, pod)} QAR'
                          ' (base ${_selectedPackage!.priceQr} QAR)'),
                      if (pod.hasShower)
                        Text(
                          isVip
                              ? 'VIP surcharge (shower included): $vipSurchargeQr QAR'
                              : _includeShower
                                  ? (_showerIsFree
                                      ? 'Shower: Free (stay ≥4h)'
                                      : 'Shower add-on: $_showerPrice QAR')
                                  : 'Shower not added',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      const Divider(),
                      Text(
                        'Total: ${_adjustedPrice(_selectedPackage!, pod) + (pod.hasShower ? (isVip ? vipSurchargeQr : (_includeShower ? _showerPrice : 0)) : 0)} QAR',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Confirm booking',
              isBusy: _isSaving,
              onPressed: () => _book(pod),
            ),
          ],
        ),
      ),
    );
  }
}
