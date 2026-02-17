import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Instances of auth and firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign in
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Merge user info just in case, or update last login?
      // For now, minimal.
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign up
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      // Create user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user info in a separate document
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': displayName,
        'profilePic':
            'https://firebasestorage.googleapis.com/v0/b/placeholder-chat.appspot.com/o/default_avatar.png?alt=media', // Placeholder
        'createdAt': Timestamp.now(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // Save FCM token to user's document
  Future<void> saveFcmToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Update both lowercase 'users' and capitalized 'Users' collections
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
      await _firestore.collection('Users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      // If user document doesn't exist, create it with minimal data
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'fcmToken': token,
        'createdAt': Timestamp.now(),
      }, SetOptions(merge: true));
      await _firestore.collection('Users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'fcmToken': token,
        'createdAt': Timestamp.now(),
      }, SetOptions(merge: true));
    }
  }

  // Remove FCM token (useful on sign out)
  Future<void> removeFcmToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': FieldValue.delete()});
    } catch (_) {}
    try {
      await _firestore
          .collection('Users')
          .doc(user.uid)
          .update({'fcmToken': FieldValue.delete()});
    } catch (_) {}
  }
}
