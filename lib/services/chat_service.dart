import 'package:chatting_app_firebase/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService {
  // get instance of firestore & auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize FCM
  Future<void> initializeFCM() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permission');
    } else {
      debugPrint(
          'User declined or has not yet granted notification permission');
    }

    // Get FCM token and store in Firestore
    String? token = await _firebaseMessaging.getToken();
    if (token != null && _auth.currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'fcmToken': token});
    }
  }

  // Get FCM token for a user
  Future<String?> getUserFcmToken(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc['fcmToken'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
    return null;
  }

  // GET ALL USERS STREAM EXCLUDING CURRENT USER
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final String? currentUserId = _auth.currentUser?.uid;
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data())
          .where((user) => user['uid'] != currentUserId)
          .toList();
    });
  }

  // SEND MESSAGE
  Future<void> sendMessage(String receiverId, String message) async {
    // get current user info
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final dynamic timestamp = FieldValue.serverTimestamp();

    // create a new message
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      isSeen: false,
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); // sort the ids (this ensures the chatRoomID is the same for any 2 people)
    String chatRoomId = ids.join('_');

    // add new message to database
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // Send FCM notification
    try {
      String? receiverFcmToken = await getUserFcmToken(receiverId);
      if (receiverFcmToken != null) {
        await sendNotification(
            receiverFcmToken, 'New message from $currentUserEmail', message);
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // Send notification via configurable cloud function endpoint
  Future<void> sendNotification(
      String receiverFcmToken, String title, String body) async {
    try {
      DocumentSnapshot cfg = await _firestore
          .collection('config')
          .doc('notificationFunction')
          .get();
      if (cfg.exists && cfg['url'] != null) {
        final String url = cfg['url'];
        final resp = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'token': receiverFcmToken,
            'title': title,
            'body': body,
          }),
        );
        debugPrint(
            'Notification function response: ${resp.statusCode} ${resp.body}');
      } else {
        debugPrint(
            'No notification function configured; skipping sending notification.');
      }
    } catch (e) {
      debugPrint('Error sending notification via function: $e');
    }
  }

  // GET MESSAGES
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    // construct a chat room ID for the two users
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // MARK MESSAGE AS SEEN
  Future<void> markMessageAsSeen(
      String messageDocId, String userId, String otherUserId) async {
    // construct a chat room ID for the two users
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageDocId)
          .update({'isSeen': true});
    } catch (e) {
      debugPrint('Error marking message as seen: $e');
    }
  }

  // SAVE CHAT BACKGROUND COLOR
  Future<void> saveChatBackgroundColor(int colorValue) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'chatBackgroundColor': colorValue});
    } catch (e) {
      debugPrint('Error saving chat background color: $e');
    }
  }

  // GET CHAT BACKGROUND COLOR STREAM
  Stream<int?> getChatBackgroundColorStream() {
    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists &&
          snapshot.data()!.containsKey('chatBackgroundColor')) {
        return snapshot.data()!['chatBackgroundColor'] as int?;
      }
      return null;
    });
  }
}
