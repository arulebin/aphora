import 'package:aphora/data/models/booking_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  Future<void> createBooking(BookingModel booking) async {
    if (booking.dateTime.isBefore(DateTime.now())) {
      throw ArgumentError('A session must be booked in the future.');
    }
    await _db.collection(_collection).doc(booking.id).set(booking.toJson());
  }

  /// 'pending' → 'confirmed' | 'declined' | 'cancelled' | 'completed'.
  Future<void> setStatus(String bookingId, String status) async {
    await _db.collection(_collection).doc(bookingId).update({'status': status});
  }

  // Sorted on the client: `where` + `orderBy` on different fields needs a
  // composite index that was never created, so the old streams errored.
  List<BookingModel> _sorted(QuerySnapshot<Map<String, dynamic>> s) {
    final list = s.docs.map((d) => BookingModel.fromJson(d.data())).toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  /// [therapistId] is the therapist's share code (that's what patients store).
  Stream<List<BookingModel>> getBookingsForTherapist(String therapistId) => _db
      .collection(_collection)
      .where('therapistId', isEqualTo: therapistId)
      .snapshots()
      .map(_sorted);

  Stream<List<BookingModel>> getBookingsForPatient(String patientId) => _db
      .collection(_collection)
      .where('patientId', isEqualTo: patientId)
      .snapshots()
      .map(_sorted);
}
