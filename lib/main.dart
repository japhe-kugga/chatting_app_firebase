import 'package:chatting_app_firebase/firebase_options.dart';
import 'package:chatting_app_firebase/services/auth_gate.dart';
import 'package:chatting_app_firebase/services/auth_service.dart';
import 'package:chatting_app_firebase/services/notification_service.dart'; // Import NotificationService
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Skip on web as it's handled by service worker
  if (kIsWeb) return;

  // If the message contains a notification, we want to show it explicitly
  // This ensures it appears in the system tray even if the app is terminated
  if (message.notification != null) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final AndroidNotification? android = message.notification?.android;
    if (android != null) {
      await flutterLocalNotificationsPlugin.show(
        id: message.notification.hashCode,
        title: message.notification!.title,
        body: message.notification!.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            // other properties...
          ),
        ),
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background handler early
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Save token on auth state change (use VAPID key for web)
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      String? token;
      try {
        if (kIsWeb) {
          token = await messaging.getToken(
            vapidKey:
                'BN-GDZa4Tbe067iE_8HeLGr9qskCLr8xYai5CLGqKCPK0SiqQ3R4lHOVM14EZc_u4sFNI3omQUsg9jDeE_Qykdw',
          );
        } else {
          // Use our service to get token or direct call
          token = await notificationService.getDeviceToken();
        }
      } catch (e) {
        // Handle error silently or log to crashlytics in production
      }

      if (token != null) {
        await AuthService().saveFcmToken(token);
      }
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
