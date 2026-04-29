import 'package:aphora/data/models/booking_model.dart';
import 'package:aphora/data/models/therapist_model.dart';
import 'package:aphora/logic/locator.dart';
import 'package:aphora/main.dart';
import 'package:aphora/ui/therapist/patient_bookings_page.dart';
import 'package:flutter/material.dart';

class TherapistPage extends StatefulWidget {
  const TherapistPage({super.key});

  @override
  State<TherapistPage> createState() => _TherapistPageState();
}

class _TherapistPageState extends State<TherapistPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  TherapistModel? _linkedTherapist;

  @override
  void initState() {
    super.initState();
    _loadTherapist();
  }

  Future<void> _loadTherapist() async {
    final user = Locator.userDatabaseService.currentUser.value;
    if (user != null && user.linkedCaregiverId!.isNotEmpty) {
      setState(() => _isLoading = true);
      final therapist = await Locator.userDatabaseService.getTherapistByCode(
        user.linkedCaregiverId!,
      );
      setState(() {
        _linkedTherapist = therapist;
        _isLoading = false;
      });
    }
  }

  Future<void> _linkTherapist() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    final therapist = await Locator.userDatabaseService.getTherapistByCode(
      code,
    );
    if (therapist != null) {
      final user = Locator.userDatabaseService.currentUser.value;
      if (user != null) {
        user.linkedCaregiverId = code;
        await Locator.userDatabaseService.updateUser(user);
        setState(() {
          _linkedTherapist = therapist;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Therapist linked successfully!')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid Therapist Code')));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _bookSession() async {
    if (_linkedTherapist == null) return;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E88E5)),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E88E5)),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final user = Locator.userDatabaseService.currentUser.value;
    if (user == null) return;

    setState(() => _isLoading = true);
    final booking = BookingModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: user.uid,
      patientName: user.name,
      therapistId: _linkedTherapist!.code,
      dateTime: dateTime,
      status: 'pending',
    );

    await Locator.bookingDatabaseService.createBooking(booking);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session booked successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
        ),
      );
    }

    final user = Locator.userDatabaseService.currentUser.value;
    final isLinked =
        user != null &&
        user.linkedCaregiverId!.isNotEmpty &&
        _linkedTherapist != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Therapist",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: isLinked ? _buildLinkedTherapistView() : _buildUnlinkedView(),
        ),
      ),
    );
  }

  Widget _buildLinkedTherapistView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Therapist Profile Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(
                  Icons.medical_services,
                  size: 40,
                  color: Color(0xFF0369A1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _linkedTherapist!.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Speech \u0026 Language Pathologist",
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _linkedTherapist!.phone,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Actions
        const Text(
          "Therapy Sessions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),

        // Book Session Button
        ElevatedButton(
          onPressed: _bookSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month),
              SizedBox(width: 8),
              Text(
                "Book New Session",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // View Bookings Button
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PatientBookingsPage()),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E88E5),
            side: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.list_alt),
              SizedBox(width: 8),
              Text(
                "View My Bookings",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnlinkedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Icon(
          Icons.people_alt_outlined,
          size: 80,
          color: Color(0xFF94A3B8),
        ),
        const SizedBox(height: 24),
        const Text(
          "Link Your Therapist",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Enter the 6-character code provided by your speech therapist to connect your accounts and track progress together.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
        ),
        const SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: Color(0xFF1E293B),
            ),
            decoration: const InputDecoration(
              counterText: "",
              hintText: "XXXXXX",
              hintStyle: TextStyle(color: Color(0xFFCBD5E1), letterSpacing: 8),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _linkTherapist,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Connect Therapist",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
