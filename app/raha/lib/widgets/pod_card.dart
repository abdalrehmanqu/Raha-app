import 'package:flutter/material.dart';
import 'package:raha/models/pod.dart';

class PodCard extends StatelessWidget {
  final Pod pod;
  final double? distanceKm;
  final VoidCallback onTap;
  final bool highlight;
  const PodCard({
    super.key,
    required this.pod,
    required this.onTap,
    this.distanceKm,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? const Color(0xFFE6F4F1) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withAlpha(28),
                child: const Icon(Icons.bed_outlined,
                    color: Colors.teal, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(pod.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            pod.type.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Terminal ${pod.terminal}'),
                    if (distanceKm != null)
                      Text('~${distanceKm!.toStringAsFixed(2)} km away',
                          style: const TextStyle(color: Colors.black54)),
                    Text(
                      pod.isAvailable ? 'Available now' : 'Currently occupied',
                      style: TextStyle(
                        color: pod.isAvailable ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        Chip(
                          label: Text(pod.type.toUpperCase()),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.teal.shade50,
                          padding: EdgeInsets.zero,
                        ),
                        if (pod.hasShower)
                          Chip(
                            avatar: const Icon(Icons.shower, size: 16),
                            label: const Text('Shower'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
