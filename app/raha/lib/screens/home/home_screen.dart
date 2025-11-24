import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:raha/config/app_config.dart';
import 'package:raha/config/routes.dart';
import 'package:raha/models/pod.dart';
import 'package:raha/providers/providers.dart';
import 'package:raha/widgets/pod_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  String _selectedType = 'all';
  String _selectedTerminal = 'all';

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _openPod(BuildContext context, Pod pod) {
    Navigator.pushNamed(context, AppRoutes.podDetails, arguments: pod);
  }

  Widget _buildMap(
    BuildContext context,
    AsyncValue<List<Pod>> podsAsync,
    AsyncValue<Position?> locationAsync,
  ) {
    if (!AppConfig.enableGoogleMaps || !AppConfig.hasGoogleMapsKey) {
      return Container(
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Map preview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text('Add a Google Maps API key in .env and platform configs to enable live map.',
                style: TextStyle(color: Colors.black87)),
            SizedBox(height: 12),
            Text('Meanwhile, browse pods below.',
                style: TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      );
    }

    return podsAsync.when(
      data: (pods) {
        if (pods.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No pods available yet')),
          );
        }
        final initialPos = CameraPosition(
          target: LatLng(pods.first.latitude, pods.first.longitude),
          zoom: 13, // Airport-level view
        );

        final markers = pods
            .map(
              (pod) => Marker(
                markerId: MarkerId(pod.id.toString()),
                position: LatLng(pod.latitude, pod.longitude),
                infoWindow: InfoWindow(
                  title: pod.name,
                  snippet: 'Terminal ${pod.terminal}',
                  onTap: () => _openPod(context, pod),
                ),
              ),
            )
            .toSet();

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
          child: GoogleMap(
            markers: markers,
            initialCameraPosition: initialPos,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled:
                locationAsync.hasValue && locationAsync.value != null,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
          ),
        ),
      );
    },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(
        height: 200,
        child: Center(child: Text('Unable to load map')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final podsAsync = ref.watch(podsProvider);
    final locationAsync = ref.watch(locationProvider);
    final profileAsync = ref.watch(profileProvider);

    List<Pod> filterPods(List<Pod> pods) {
      return pods.where((pod) {
        final matchesType =
            _selectedType == 'all' || pod.type.toLowerCase() == _selectedType;
        final matchesTerminal = _selectedTerminal == 'all' ||
            pod.terminal.toLowerCase() == _selectedTerminal;
        return matchesType && matchesTerminal;
      }).toList();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(podsProvider);
        ref.invalidate(locationProvider);
        await Future.wait([
          ref.read(podsProvider.future),
          ref.read(locationProvider.future),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: ClipOval(
                  child: Image(
                    image: AssetImage('assets/rahaLogo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profileAsync.maybeWhen(
                      data: (profile) => 'Hi ${profile?.fullName ?? 'traveler'},',
                      orElse: () => 'Hi traveler,',
                    ),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Text('Find your next oasis pod'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMap(context, podsAsync, locationAsync),
          const SizedBox(height: 16),
          podsAsync.when(
            data: (pods) {
              final terminals = <String>{...pods.map((p) => p.terminal.toLowerCase())}..remove('');
              final terminalChips = ['all', ...terminals.toList()..sort()];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter pods',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All types'),
                        selected: _selectedType == 'all',
                        onSelected: (_) => setState(() => _selectedType = 'all'),
                      ),
                      ChoiceChip(
                        label: const Text('Family'),
                        selected: _selectedType == 'family',
                        onSelected: (_) => setState(() => _selectedType = 'family'),
                      ),
                      ChoiceChip(
                        label: const Text('Normal'),
                        selected: _selectedType == 'normal',
                        onSelected: (_) => setState(() => _selectedType = 'normal'),
                      ),
                      ChoiceChip(
                        label: const Text('VIP'),
                        selected: _selectedType == 'vip',
                        onSelected: (_) => setState(() => _selectedType = 'vip'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: terminalChips
                          .map((terminal) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(
                                      terminal == 'all' ? 'All terminals' : 'Terminal $terminal'),
                                  selected: _selectedTerminal == terminal,
                                  onSelected: (_) =>
                                      setState(() => _selectedTerminal = terminal),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          if (locationAsync.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Location unavailable. Showing pods without distance.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else if (locationAsync.hasValue && locationAsync.value == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Location permission not granted. Showing pods without distance.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nearby pods',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.bookings),
                child: const Text('View my bookings'),
              ),
            ],
          ),
          podsAsync.when(
            data: (pods) {
              if (pods.isEmpty) {
                return const Text('No pods published yet.');
              }
              final filtered = filterPods(pods);
              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No pods match these filters. Try adjusting filters.'),
                );
              }
              final position = locationAsync.valueOrNull;
              return Column(
                children: filtered
                    .map(
                      (pod) => PodCard(
                        pod: pod,
                        highlight: pod.type.toLowerCase() == 'vip',
                        distanceKm: position != null
                            ? ref
                                .read(locationServiceProvider)
                                .distanceInKm(position.latitude,
                                    position.longitude, pod.latitude, pod.longitude)
                            : null,
                        onTap: () => _openPod(context, pod),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () =>
                const Center(child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                )),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Could not load pods: $error'),
            ),
          ),
        ],
      ),
    );
  }
}
