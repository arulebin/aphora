import 'package:aphora/data/models/booking_model.dart';
import 'package:aphora/data/models/therapist_model.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/login_page.dart';
import 'package:aphora/ui/patient_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class TherapistDashboardPage extends StatefulWidget {
  const TherapistDashboardPage({super.key});

  @override
  State<TherapistDashboardPage> createState() => _TherapistDashboardPageState();
}

class _TherapistDashboardPageState extends State<TherapistDashboardPage> {
  final TherapistModel? therapist =
      Locator.userDatabaseService.currentTherapist.value;
  List<UserModel> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    if (therapist == null) return;
    try {
      final patients = await Locator.userDatabaseService.getTherapistPatients(
        therapist!.code,
      );
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching patients: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyCode() {
    if (therapist != null) {
      Clipboard.setData(ClipboardData(text: therapist!.code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Therapist Code copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (therapist == null) {
      return const Scaffold(
        body: Center(child: Text("Error: Therapist not found")),
      );
    }

    return Scaffold(
      backgroundColor: DuoColors.surface,
      appBar: AppBar(
        title: const Text('Therapist Dashboard'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Locator.userDatabaseService.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPatients,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Therapist Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DuoColors.border, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${therapist!.name}',
                            style: DuoTextStyles.heading,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your unique code for patients:',
                            style: DuoTextStyles.label,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  therapist!.code,
                                  style: DuoTextStyles.body.copyWith(
                                    color: Colors.purple,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: _copyCode,
                                icon: const Icon(
                                  Icons.copy,
                                  color: Colors.purple,
                                ),
                                tooltip: 'Copy Code',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Your Patients', style: DuoTextStyles.heading),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _patients.isEmpty
                          ? Center(
                              child: Text(
                                'No patients linked yet.\nShare your code to get started!',
                                textAlign: TextAlign.center,
                                style: DuoTextStyles.label,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _patients.length,
                              itemBuilder: (context, index) {
                                final patient = _patients[index];
                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: DuoColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: DuoColors.blue
                                          .withOpacity(0.1),
                                      child: const Icon(
                                        Icons.person,
                                        color: DuoColors.blue,
                                      ),
                                    ),
                                    title: Text(
                                      patient.name,
                                      style: DuoTextStyles.body,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Aphasia Type: ${patient.aphasiaType}',
                                        ),
                                        Text(
                                          'Progress Score: ${patient.progressScore}',
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: DuoColors.border,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PatientDetailPage(
                                                patient: patient,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                    Text('Upcoming Bookings', style: DuoTextStyles.heading),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<List<BookingModel>>(
                        stream: Locator.bookingDatabaseService
                            .getBookingsForTherapist(therapist!.code),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          final bookings = snapshot.data ?? [];
                          if (bookings.isEmpty) {
                            return Center(
                              child: Text(
                                'No upcoming sessions booked.',
                                style: DuoTextStyles.label,
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: DuoColors.border,
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: DuoColors.green
                                        .withOpacity(0.1),
                                    child: const Icon(
                                      Icons.calendar_month,
                                      color: DuoColors.green,
                                    ),
                                  ),
                                  title: Text(
                                    booking.patientName,
                                    style: DuoTextStyles.body,
                                  ),
                                  subtitle: Text(
                                    '${booking.dateTime.month}/${booking.dateTime.day}/${booking.dateTime.year} at ${TimeOfDay.fromDateTime(booking.dateTime).format(context)}',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
