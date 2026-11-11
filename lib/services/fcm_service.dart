
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  // Callback used to update the Flutter UI.
  final void Function(RemoteMessage message, String handler) onMessage;

  FCMService({required this.onMessage});

  Future<void> initialize() async {
    // Request notification permission.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Notification permission: ${settings.authorizationStatus}',
    );

    // Get the current device token.
    final token = await _messaging.getToken();

    debugPrint('FCM token: $token');

    // Handle messages received while the app is visible.
    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.messageId}');

      onMessage(message, 'onMessage');
    });

    // Handle notification taps when app is backgrounded.
    _openedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Background notification opened');

      onMessage(message, 'onMessageOpenedApp');
    });

    // Handle notification tap that launches a terminated app.
    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App launched from notification');

      onMessage(initialMessage, 'getInitialMessage');
    }
  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
  }
}
