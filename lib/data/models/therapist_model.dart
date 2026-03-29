import 'package:aphora/data/models/usermodel.dart';

class TherapistModel {
  final String id;
  final String name;
  final String phone; // Can be used for login
  final String code; // The shareable code

  TherapistModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.code,
  });

  factory TherapistModel.fromMap(Map<String, dynamic> map, String id) {
    return TherapistModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      code: map['code'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'code': code};
  }
}
