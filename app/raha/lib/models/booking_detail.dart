import 'package:intl/intl.dart';
import 'package:raha/models/pod.dart';
import 'package:raha/models/raha_package.dart';

class BookingDetail {
  final dynamic id;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final Pod? pod;
  final RahaPackage? package;
  final DateTime? createdAt;

  BookingDetail({
    required this.id,
    required this.status,
    required this.startTime,
    required this.endTime,
    this.pod,
    this.package,
    this.createdAt,
  });

  factory BookingDetail.fromMap(Map<String, dynamic> map) {
    return BookingDetail(
      id: map['id'],
      status: map['status'] ?? 'pending',
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      pod: map['pod'] != null ? Pod.fromMap(map['pod']) : null,
      package:
          map['package'] != null ? RahaPackage.fromMap(map['package']) : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }

  String get readableRange {
    final formatter = DateFormat('MMM d, h:mm a');
    return '${formatter.format(startTime)} → ${formatter.format(endTime)}';
  }

  bool get isActive {
    return status == 'confirmed' || status == 'in_progress';
  }
}
