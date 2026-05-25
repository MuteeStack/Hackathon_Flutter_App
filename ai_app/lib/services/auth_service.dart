/// Firebase Auth & Google Sign-In service with Realtime Database
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ─── Sign Up with Email/Password ────────────────────────────────────────────
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    await _createUserDoc(cred.user!, displayName: displayName);
    return cred;
  }

  // ─── Sign In with Email/Password ────────────────────────────────────────────
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ─── Continue with Google ───────────────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // Use Firebase Auth native popup for web to avoid configuration issues
      final googleProvider = GoogleAuthProvider();
      final cred = await _auth.signInWithPopup(googleProvider);
      await _createUserDoc(cred.user!);
      return cred;
    } else {
      // Mobile logic
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      await _createUserDoc(cred.user!);
      return cred;
    }
  }

  // ─── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── RTDB: Create/Update User Document ─────────────────────────────────
  Future<void> _createUserDoc(User user, {String? displayName}) async {
    final ref = _db.ref('users/${user.uid}');
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? 'User',
        'photoURL': user.photoURL,
        'createdAt': ServerValue.timestamp,
        'lastLogin': ServerValue.timestamp,
      });
    } else {
      await ref.update({'lastLogin': ServerValue.timestamp});
    }
  }

  // ─── RTDB: Save Request to History ─────────────────────────────────────
  Future<String?> saveToHistory({
    required String userId,
    required Map<String, dynamic> responseData,
    required String originalMessage,
  }) async {
    final ref = _db.ref('users/$userId/history').push();
    await ref.set({
      'originalMessage': originalMessage,
      'response': responseData,
      'createdAt': ServerValue.timestamp,
    });
    return ref.key;
  }

  // ─── RTDB: Update Booking Status ──────────────────────────────────────────
  Future<void> updateBookingStatus({
    required String userId,
    required String historyKey,
    required String status,
  }) async {
    await _db.ref('users/$userId/history/$historyKey/response/booking').update({
      'status': status,
    });
  }

  // ─── RTDB: Fetch History ────────────────────────────────────────────────
  Stream<DatabaseEvent> getHistoryStream(String userId) {
    return _db.ref('users/$userId/history').orderByChild('createdAt').limitToLast(50).onValue;
  }

  // ─── RTDB: Fetch User Profile ───────────────────────────────────────────
  Stream<DatabaseEvent> getUserProfileStream(String userId) {
    return _db.ref('users/$userId').onValue;
  }

  // ─── RTDB: Update User Profile ──────────────────────────────────────────
  Future<void> updateUserProfile({
    required String userId,
    required String displayName,
    required String activeLocation,
    required String phone,
  }) async {
    await _db.ref('users/$userId').update({
      'displayName': displayName,
      'activeLocation': activeLocation,
      'phone': phone,
    });
  }
}
