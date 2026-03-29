import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String patientId;
  final String patientName;
  final String therapistId;
  final DateTime dateTime;
  final String status;

  BookingModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.therapistId,
    required this.dateTime,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'therapistId': therapistId,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? 'Unknown Patient',
      therapistId: json['therapistId'] ?? '',
      dateTime: (json['dateTime'] as Timestamp).toDate(),
      status: json['status'] ?? 'pending',
    );
  }
}
