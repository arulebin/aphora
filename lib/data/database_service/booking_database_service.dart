import 'package:aphora/data/models/booking_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  Future<void> createBooking(BookingModel booking) async {
    await _db.collection(_collection).doc(booking.id).set(booking.toJson());
  }

  Stream<List<BookingModel>> getBookingsForTherapist(String therapistId) {
    return _db
        .collection(_collection)
        .where('therapistId', isEqualTo: therapistId)
        .orderBy('dateTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<List<BookingModel>> getBookingsForPatient(String patientId) {
    return _db
        .collection(_collection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromJson(doc.data()))
              .toList(),
        );
  }
}
