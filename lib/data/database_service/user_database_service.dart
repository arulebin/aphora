import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/data/models/therapist_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserDatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  ValueNotifier<UserModel?> currentUser = ValueNotifier(null);
  ValueNotifier<TherapistModel?> currentTherapist = ValueNotifier(null);

  final String userCollection = "users";
  final String therapistCollection = "therapists";

  /// Convert phone → email
  String _phoneToEmail(String phone) {
    return "$phone@aphora.com";
  }

  String _therapistEmail(String phone) {
    return "$phone@aphorat.com";
  }

  /// =========================
  /// 🔐 SIGN UP
  /// =========================
  Future<UserModel?> signUp({
    required String phone,
    required String password,
    required String name,
    required int age,
    required String gender,
    required String aphasiaType,
    required String severityLevel,
  }) async {
    try {
      final email = _phoneToEmail(phone);
      print("🔐 Starting signup for: $email");

      // 🔥 Check if user already exists in DB (by phone)
      print("🔍 Checking if user exists...");
      final existing = await _db
          .collection(userCollection)
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception("User with this phone already exists");
      }

      // Create Firebase Auth user
      print("🔐 Creating Firebase Auth user...");
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = cred.user;
      if (firebaseUser == null) {
        throw Exception("Failed to create auth user");
      }

      print("✅ Auth user created: ${firebaseUser.uid}");

      // Create UserModel
      final newUser = UserModel(
        uid: firebaseUser.uid,
        name: name,
        email: email,
        phoneNumber: phone,
        role: "patient",
        age: age,
        gender: gender,
        languagePreference: "Tamil",
        aphasiaType: aphasiaType,
        severityLevel: severityLevel,
        goals: [],
        sessionsCompleted: 0,
        progressScore: 0,
        completedExercises: [],
        averageAccuracy: 0.0,
        averageFluency: 0.0,
        linkedCaregiverId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      print("💾 Saving user to Firestore...");
      await _db
          .collection(userCollection)
          .doc(firebaseUser.uid)
          .set(newUser.toMap());
      currentUser.value = newUser;
      print("✅ User successfully created and saved!");
      return newUser;
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("❌ Signup Error: $e");
      rethrow;
    }
  }

  /// =========================
  /// 🔐 LOGIN
  /// =========================
  Future<UserModel?> login({
    required String phone,
    required String password,
  }) async {
    try {
      final email = _phoneToEmail(phone);

      // Firebase Auth login
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = cred.user;
      if (firebaseUser == null) return null;

      // 🔥 Ensure user exists in Firestore
      final doc = await _db
          .collection(userCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) {
        throw Exception("User exists in Auth but not in DB");
      }

      currentUser.value = UserModel.fromMap(doc.data()!);
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  /// =========================
  /// 👤 GET CURRENT USER
  /// =========================
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _db
        .collection(userCollection)
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  /// =========================
  /// 🔄 UPDATE USER
  /// =========================
  Future<void> updateUser(UserModel user) async {
    await _db.collection(userCollection).doc(user.uid).update(user.toMap());
  }

  /// =========================
  /// 🚪 LOGOUT
  /// =========================
  Future<void> logout() async {
    await _auth.signOut();
    currentUser.value = null;
    currentTherapist.value = null;
  }

  /// =========================
  /// ❌ DELETE USER (optional)
  /// =========================
  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection(userCollection).doc(user.uid).delete();
    await user.delete();
  }

  /// =========================
  /// 👨‍⚕️ THERAPIST LOGIN
  /// =========================
  Future<TherapistModel?> loginTherapist({
    required String phone,
    required String password,
    String? name,
  }) async {
    try {
      final email = _therapistEmail(phone);
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = cred.user;
      if (firebaseUser == null) return null;

      final doc = await _db
          .collection(therapistCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) {
        // Automatically create a document if logging in for the time with a dummy password
        // In a real app we would have a signup for Therapist.
        final newTherapist = TherapistModel(
          id: firebaseUser.uid,
          name: name ?? "Dr. Therapist",
          phone: phone,
          code: firebaseUser.uid
              .substring(0, 6)
              .toUpperCase(), // Generate random code
        );
        await _db
            .collection(therapistCollection)
            .doc(firebaseUser.uid)
            .set(newTherapist.toMap());
        currentTherapist.value = newTherapist;
        return newTherapist;
      }

      final therapist = TherapistModel.fromMap(doc.data()!, doc.id);
      currentTherapist.value = therapist;
      return therapist;
    } catch (e) {
      print("Therapist Login Error: $e");

      // If it's an invalid-credential error, it usually means the user doesn't exist yet
      if (e is FirebaseAuthException &&
          (e.code == 'invalid-credential' || e.code == 'user-not-found')) {
        print("Auto-creating therapist account...");
        try {
          final email = _therapistEmail(phone);
          final cred = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          final firebaseUser = cred.user;
          if (firebaseUser != null) {
            final newTherapist = TherapistModel(
              id: firebaseUser.uid,
              name: name ?? "Dr. Therapist",
              phone: phone,
              code: firebaseUser.uid.substring(0, 6).toUpperCase(),
            );
            await _db
                .collection(therapistCollection)
                .doc(firebaseUser.uid)
                .set(newTherapist.toMap());
            currentTherapist.value = newTherapist;
            return newTherapist;
          }
        } catch (e2) {
          print("Failed Auto-creating therapist: $e2");
        }
      }
      return null;
    }
  }

  Future<List<UserModel>> getTherapistPatients(String code) async {
    final snapshot = await _db
        .collection(userCollection)
        .where('linkedCaregiverId', isEqualTo: code)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<TherapistModel?> getTherapistByCode(String code) async {
    try {
      final snapshot = await _db
          .collection(therapistCollection)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return TherapistModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print("Error getting therapist by code: $e");
      return null;
    }
  }
}
