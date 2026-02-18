import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Top-level background message handler
/// This must be outside the class to work when the app is terminated or in the background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle the background message here
  print("Handling a background message: ${message.messageId}");
}

const String kNotificationChannelId = 'high_importance_channel';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize all notification settings
  Future<void> initialize() async {
    // Request user permissions
    await _requestPermission();

    // Setup local notification settings for Android and iOS
    await _initLocalNotifications();

    // Register the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configure foreground listeners
    _configureFCM();

    // Fetch and display the device token for testing
    await getDeviceToken();
  }

  /// Request notification permissions from the user
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notification plugins for foreground pop-ups
  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;

    // Android specific settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/Darwin specific settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle logic when a user taps on the notification
      },
    );

    // Create the High Importance Channel for Android devices
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createAndroidNotificationChannel();
    }
  }

  /// Create a high importance channel to ensure pop-up/heads-up display
  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      kNotificationChannelId,
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max, // Mandatory for pop-ups
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Configure FCM listeners for foreground and background interactions
  void _configureFCM() {
    // Listener for when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showLocalNotification(message);
      }
    });

    // Listener for when the app is opened via a notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App opened from notification");
    });
  }

  /// Manually trigger a local notification to show the pop-up
  Future<void> showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;

    if (notification != null) {
      await _flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            kNotificationChannelId,
            'High Importance Notifications',
            channelDescription: 'Important notifications channel.',
            importance: Importance.max, // Required for pop-up
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  /// Fetch the FCM Device Token and print it to the Debug Console
  Future<String?> getDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print("*********************************************");
        print("YOUR FCM TOKEN IS: $token");
        print("*********************************************");
      }
      return token;
    } catch (e) {
      print("Error getting device token: $e");
      return null;
    }
  }
}
