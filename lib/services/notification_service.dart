import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission for notifications
    await _requestPermission();

    // Initialize local notifications
    await _initLocalNotifications();

    // Configure FCM listeners
    _configureFCM();

    // Automatically fetch and print the token during initialization
    await getDeviceToken();
  }

  // Request permissions
  Future<void> _requestPermission() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  // Initialize local notifications for heads-up display in foreground
  Future<void> _initLocalNotifications() async {
    if (kIsWeb) {
      return;
    }

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        // Handle notification tap logic here
      },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _createAndroidNotificationChannel();
    }
  }

  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Configure FCM listeners
  void _configureFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap opening app
    });
  }

  // Show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // Get FCM Token and PRINT it to Debug Console
  Future<String?> getDeviceToken() async {
    try {
      String? token;
      if (kIsWeb) {
        token = await _firebaseMessaging.getToken(
            vapidKey:
                'BN-GDZa4Tbe067iE_8HeLGr9qskCLr8xYai5CLGqKCPK0SiqQ3R4lHOVM14EZc_u4sFNI3omQUsg9jDeE_Qykdw');
      } else {
        token = await _firebaseMessaging.getToken();
      }

      // THIS IS THE IMPORTANT PART: Printing the token so you can see it
      if (token != null) {
        print("*********************************************");
        print("YOUR FCM TOKEN IS: $token");
        print("*********************************************");
      } else {
        print("FCM Token is null. Check your VAPID key or Firebase setup.");
      }

      return token;
    } catch (e) {
      print("Error getting device token: $e");
      return null;
    }
  }
}
