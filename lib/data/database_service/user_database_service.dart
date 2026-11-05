import 'package:aphora/data/models/practice_record.dart';
import 'package:aphora/data/models/therapist_model.dart';
import 'package:aphora/data/models/usermodel.dart';
import 'package:aphora/logic/comfort_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Thrown with a message that is safe to show to the user.
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class UserDatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ValueNotifier<UserModel?> currentUser = ValueNotifier(null);
  final ValueNotifier<TherapistModel?> currentTherapist = ValueNotifier(null);

  final String userCollection = 'users';
  final String therapistCollection = 'therapists';

  // Phone numbers are mapped to synthetic e-mails so Firebase email/password
  // auth can be used without SMS costs. Patients and therapists live in
  // separate e-mail domains so one phone can hold both roles.
  String _phoneToEmail(String phone) => '$phone@aphora.com';
  String _therapistEmail(String phone) => '$phone@aphorat.com';

  static String _authMessage(FirebaseAuthException e) => switch (e.code) {
        'email-already-in-use' =>
          'An account with this phone number already exists. Please sign in.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-email' =>
          'Phone number or password is incorrect.',
        'weak-password' => 'Please choose a password of at least 6 characters.',
        'network-request-failed' =>
          'No internet connection. Please check and try again.',
        'too-many-requests' =>
          'Too many attempts. Please wait a minute and try again.',
        _ => 'Could not sign in (${e.code}). Please try again.',
      };

  // ── Patients ──────────────────────────────────────────────────────────

  /// Creates the Auth user and the Firestore profile. If the profile write
  /// fails the Auth user is deleted again, so no orphan accounts remain.
  /// Duplicate phones are caught by Auth (`email-already-in-use`) rather
  /// than an unauthenticated Firestore query, which security rules block.
  Future<UserModel> signUp({
    required String phone,
    required String password,
    required String name,
    required int age,
    required String gender,
    required String aphasiaType,
    required String severityLevel,
    String role = 'patient',
  }) async {
    UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: _phoneToEmail(phone),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authMessage(e));
    }
    final firebaseUser = cred.user!;
    final now = DateTime.now();
    final lang = ComfortSettings.instance.language.value.name == 'english'
        ? 'English'
        : 'Tamil';
    final newUser = UserModel(
      uid: firebaseUser.uid,
      name: name,
      email: _phoneToEmail(phone),
      phoneNumber: phone,
      role: role,
      age: age,
      gender: gender,
      languagePreference: lang,
      aphasiaType: aphasiaType,
      severityLevel: severityLevel,
      goals: const [],
      sessionsCompleted: 0,
      progressScore: 0,
      completedExercises: const [],
      linkedCaregiverId: '',
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _db
          .collection(userCollection)
          .doc(firebaseUser.uid)
          .set(newUser.toMap());
    } catch (e) {
      try {
        await firebaseUser.delete();
      } catch (_) {}
      throw AuthFailure(
        'Your account could not be saved. Please check your connection and try again.',
      );
    }
    currentUser.value = newUser;
    return newUser;
  }

  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(
        email: _phoneToEmail(phone),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authMessage(e));
    }
    final doc =
        await _db.collection(userCollection).doc(cred.user!.uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw AuthFailure(
        'We found your login but not your profile. Please create the account again.',
      );
    }
    final user = UserModel.fromMap(doc.data()!);
    currentUser.value = user;
    return user;
  }

  Future<bool> restoreSession() async {
    final firebaseUser = await _auth.authStateChanges().first;
    if (firebaseUser == null) return false;
    try {
      final userDoc =
          await _db.collection(userCollection).doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        currentUser.value = UserModel.fromMap(userDoc.data()!);
        return true;
      }
      final therapistDoc = await _db
          .collection(therapistCollection)
          .doc(firebaseUser.uid)
          .get();
      if (therapistDoc.exists) {
        currentTherapist.value =
            TherapistModel.fromMap(therapistDoc.data()!, therapistDoc.id);
        return true;
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
    return false;
  }

  Future<UserModel?> refreshCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection(userCollection).doc(uid).get();
    if (!doc.exists) return null;
    final user = UserModel.fromMap(doc.data()!);
    currentUser.value = user;
    return user;
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection(userCollection).doc(user.uid).update(user.toMap());
    if (currentUser.value?.uid == user.uid) currentUser.value = user;
  }

  /// Links the signed-in patient to a therapist by code. Returns the
  /// therapist, or null when the code doesn't exist.
  Future<TherapistModel?> linkTherapist(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final user = currentUser.value;
    if (user == null || code.isEmpty) return null;
    final therapist = await getTherapistByCode(code);
    if (therapist == null) return null;
    await updateUser(user.copyWith(linkedCaregiverId: code));
    return therapist;
  }

  Future<void> unlinkTherapist() async {
    final user = currentUser.value;
    if (user == null) return;
    await _db
        .collection(userCollection)
        .doc(user.uid)
        .update({'linkedCaregiverId': ''});
    final updated = user.copyWith(updatedAt: DateTime.now());
    updated.linkedCaregiverId = '';
    currentUser.value = updated;
  }

  Future<void> setLanguagePreference(String language) async {
    final user = currentUser.value;
    if (user == null) return;
    await updateUser(user.copyWith(languagePreference: language));
  }

  /// Records one scored answer: rolling averages, daily activity and an
  /// attempt document for the therapist. Does NOT count a session — call
  /// [recordSession] once when the patient finishes (previously every
  /// attempt, even an empty one, bumped `sessionsCompleted`).
  Future<UserModel?> recordExerciseResult({
    required String taskId,
    required double accuracy,
    double? fluency,
    String category = 'practice',
    String target = '',
    String spoken = '',
    String method = 'device',
    bool assisted = false,
    int hintsUsed = 0,
  }) async {
    final user = currentUser.value;
    if (user == null) return null;

    final acc = accuracy.clamp(0.0, 100.0).toDouble();
    final flu = (fluency ?? acc).clamp(0.0, 100.0).toDouble();
    final prior = user.totalAttempts;
    final n = prior + 1;
    double rolling(double old, double next) =>
        prior <= 0 ? next : ((old * prior) + next) / n;

    final key = dayKey(DateTime.now());
    final activity = Map<String, int>.from(user.dailyActivity)
      ..update(key, (v) => v + 1, ifAbsent: () => 1);
    final exercises = {...user.completedExercises, taskId}.toList();

    final updated = user.copyWith(
      totalAttempts: n,
      averageAccuracy: rolling(user.averageAccuracy, acc),
      averageFluency: rolling(user.averageFluency, flu),
      progressScore:
          ((user.progressScore * 0.8) + (acc * 0.2)).clamp(0.0, 100.0),
      dailyActivity: activity,
      completedExercises: exercises,
    );

    final ref = _db.collection(userCollection).doc(user.uid);
    final batch = _db.batch()
      ..update(ref, {
        'totalAttempts': updated.totalAttempts,
        'averageAccuracy': updated.averageAccuracy,
        'averageFluency': updated.averageFluency,
        'progressScore': updated.progressScore,
        'dailyActivity': updated.dailyActivity,
        'completedExercises': updated.completedExercises,
        'updatedAt': DateTime.now().toIso8601String(),
      })
      ..set(
        ref.collection('attempts').doc(),
        AttemptRecord(
          taskId: taskId,
          category: category,
          target: target,
          spoken: spoken,
          score: acc,
          method: method,
          assisted: assisted,
          hintsUsed: hintsUsed,
          createdAt: DateTime.now(),
        ).toMap(),
      );
    await batch.commit();
    currentUser.value = updated;
    return updated;
  }

  Future<void> recordSession(SessionRecord session) async {
    final user = currentUser.value;
    if (user == null) return;
    final ref = _db.collection(userCollection).doc(user.uid);
    final batch = _db.batch()
      ..set(ref.collection('sessions').doc(), session.toMap())
      ..update(ref, {'sessionsCompleted': FieldValue.increment(1)});
    await batch.commit();
    currentUser.value =
        user.copyWith(sessionsCompleted: user.sessionsCompleted + 1);
  }

  Future<void> savePreAssessment({
    required double score,
    required String recommendedFocus,
  }) async {
    final user = currentUser.value;
    if (user == null) return;
    final now = DateTime.now();
    await _db.collection(userCollection).doc(user.uid).update({
      'preAssessmentScore': score,
      'preAssessmentDate': now.toIso8601String(),
      'recommendedFocus': recommendedFocus,
    });
    currentUser.value = user.copyWith(
      preAssessmentScore: score,
      preAssessmentDate: now,
      recommendedFocus: recommendedFocus,
    );
  }

  Future<List<AttemptRecord>> getRecentAttempts(
    String uid, {
    int limit = 30,
  }) async {
    final snap = await _db
        .collection(userCollection)
        .doc(uid)
        .collection('attempts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => AttemptRecord.fromMap(d.id, d.data()))
        .toList()
        .reversed
        .toList();
  }

  Future<List<SessionRecord>> getRecentSessions(
    String uid, {
    int limit = 20,
  }) async {
    final snap = await _db
        .collection(userCollection)
        .doc(uid)
        .collection('sessions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => SessionRecord.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> logout() async {
    await _auth.signOut();
    currentUser.value = null;
    currentTherapist.value = null;
  }

  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection(userCollection).doc(user.uid).delete();
    await user.delete();
    currentUser.value = null;
  }

  // ── Therapists ────────────────────────────────────────────────────────

  /// Signs in an existing therapist. Never creates accounts — the old
  /// behaviour auto-created a therapist on any failed login, so anyone
  /// could become a "therapist" and read linked patients.
  Future<TherapistModel> loginTherapist({
    required String phone,
    required String password,
  }) async {
    UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(
        email: _therapistEmail(phone),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authMessage(e));
    }
    final doc = await _db
        .collection(therapistCollection)
        .doc(cred.user!.uid)
        .get();
    if (!doc.exists) {
      await _auth.signOut();
      throw AuthFailure('No therapist profile found for this number.');
    }
    final therapist = TherapistModel.fromMap(doc.data()!, doc.id);
    currentTherapist.value = therapist;
    return therapist;
  }

  /// Explicit therapist registration.
  Future<TherapistModel> registerTherapist({
    required String phone,
    required String password,
    required String name,
  }) async {
    UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: _therapistEmail(phone),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_authMessage(e));
    }
    final uid = cred.user!.uid;
    final therapist = TherapistModel(
      id: uid,
      name: name,
      phone: phone,
      code: uid.substring(0, 6).toUpperCase(),
    );
    try {
      await _db
          .collection(therapistCollection)
          .doc(uid)
          .set(therapist.toMap());
    } catch (_) {
      try {
        await cred.user!.delete();
      } catch (_) {}
      throw AuthFailure('Your account could not be saved. Please try again.');
    }
    currentTherapist.value = therapist;
    return therapist;
  }

  Future<List<UserModel>> getTherapistPatients(String code) async {
    final snapshot = await _db
        .collection(userCollection)
        .where('linkedCaregiverId', isEqualTo: code)
        .get();
    final list =
        snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<void> setTherapistNote(String patientUid, String note) async {
    await _db.collection(userCollection).doc(patientUid).update({
      'therapistNote': note.trim(),
    });
  }

  Future<TherapistModel?> getTherapistByCode(String code) async {
    try {
      final snapshot = await _db
          .collection(therapistCollection)
          .where('code', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return TherapistModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      debugPrint('Error getting therapist by code: $e');
      return null;
    }
  }
}
