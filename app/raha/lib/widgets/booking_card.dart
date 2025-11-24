import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raha/models/booking_detail.dart';

class BookingCard extends StatelessWidget {
  final BookingDetail booking;
  final VoidCallback? onTap;
  final VoidCallback? onExtend;
  final Widget? actions;
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onExtend,
    this.actions,
  });

    String _statusLabel() {
      switch (booking.status) {
        case 'confirmed':
          return 'Confirmed';
        case 'in_progress':
          return 'In progress';
        case 'pending':
          return 'Pending';
        case 'completed':
          return 'Completed';
        case 'cancelled':
        return 'Cancelled';
      default:
        return booking.status;
    }
  }

    Color _statusColor() {
      switch (booking.status) {
        case 'confirmed':
          return Colors.green;
        case 'in_progress':
          return Colors.teal;
        case 'pending':
          return Colors.orange;
        case 'completed':
          return Colors.grey;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, h:mm a');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bed, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(booking.pod?.name ?? 'Pod',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  if (booking.isActive && onExtend != null)
                    TextButton.icon(
                      onPressed: onExtend,
                      icon: const Icon(Icons.more_time),
                      label: const Text('Extend'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Chip(
                    label: Text(_statusLabel()),
                    backgroundColor: _statusColor().withAlpha(22),
                    labelStyle: TextStyle(
                        color: _statusColor(), fontWeight: FontWeight.w600),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                  if (booking.pod?.terminal != null &&
                      booking.pod!.terminal.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.flight_takeoff, size: 16),
                      label: Text('Terminal ${booking.pod!.terminal}'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(booking.package?.name ?? 'Package',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                '${formatter.format(booking.startTime)} → ${formatter.format(booking.endTime)}',
                style: const TextStyle(color: Colors.black54),
              ),
              if (actions != null) ...[
                const SizedBox(height: 10),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 6),
                actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
