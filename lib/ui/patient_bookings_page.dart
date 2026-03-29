import 'package:aphora/data/models/booking_model.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientBookingsPage extends StatelessWidget {
  const PatientBookingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Locator.userDatabaseService.currentUser.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: const Center(child: Text("Please log in to view bookings.")),
      );
    }

    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: DuoColors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: Locator.bookingDatabaseService.getBookingsForPatient(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                "No bookings found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final dateStr = DateFormat.yMMMd().format(booking.dateTime);
              final timeStr = DateFormat.jm().format(booking.dateTime);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: DuoColors.greenLight,
                    child: Icon(Icons.event, color: DuoColors.green),
                  ),
                  title: Text(
                    "Session on $dateStr",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Time: $timeStr\nStatus: ${booking.status}"),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
