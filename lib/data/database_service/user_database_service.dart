import 'package:aphora/data/models/usermodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String userCollection = "users";

  /// Convert phone → email
  String _phoneToEmail(String phone) {
    return "$phone@aphora.com";
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

      // 🔥 Check if user already exists in DB (by phone)
      final existing = await _db
          .collection(userCollection)
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception("User already exists");
      }

      // Create Firebase Auth user
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = cred.user;
      if (firebaseUser == null) return null;

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
        linkedCaregiverId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _db
          .collection(userCollection)
          .doc(firebaseUser.uid)
          .set(newUser.toMap());

      return newUser;
    } catch (e) {
      print("Signup Error: $e");
      return null;
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
}
