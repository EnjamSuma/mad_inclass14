
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'services/fcm_service.dart';

// Background processing must not directly update widgets.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cloud Courier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: const CloudCourierScreen(),
    );
  }
}

class CloudCourierScreen extends StatefulWidget {
  const CloudCourierScreen({super.key});

  @override
  State<CloudCourierScreen> createState() =>
      _CloudCourierScreenState();
}

class _CloudCourierScreenState
    extends State<CloudCourierScreen> {
  late final FCMService _fcmService;

  String _title = 'Welcome to Cloud Courier';
  String _image = 'assets/images/default.png';
  String _lastHandler = 'None';
  String _messageId = 'None';
  String _diagnostic = 'Waiting for a message...';

  int _messageCount = 0;

  @override
  void initState() {
    super.initState();

    _fcmService = FCMService(
      onMessage: _handleMessage,
    );

    _fcmService.initialize().catchError((Object error) {
      debugPrint('FCM initialization error: $error');

      if (!mounted) return;

      setState(() {
        _diagnostic = 'FCM initialization failed: $error';
      });
    });
  }

  void _handleMessage(
    RemoteMessage message,
    String handler,
  ) {
    if (!mounted) return;

    final data = message.data;
    final action = data['action'];
    final asset = data['asset'];

    setState(() {
      _messageCount++;
      _lastHandler = handler;
      _messageId = message.messageId ?? 'Unavailable';

      // Reject missing or unsupported payload values.
      if (action != 'update_ui') {
        _diagnostic =
            'Invalid action: ${action ?? "missing"}';
        return;
      }

      if (asset != 'default' && asset != 'promo') {
        _diagnostic =
            'Invalid asset: ${asset ?? "missing"}';
        return;
      }

      // Only supported values can select an image.
      _image = asset == 'promo'
          ? 'assets/images/promo.png'
          : 'assets/images/default.png';

      _title = asset == 'promo'
          ? 'New Promotion Received!'
          : 'Campus Update Received!';

      _diagnostic = 'Valid message processed successfully';
    });
  }

  @override
  void dispose() {
    _fcmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Courier'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_outlined,
                size: 70,
                color: Colors.teal,
              ),
              const SizedBox(height: 16),

              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Image.asset(
                _image,
                height: 180,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 25),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages received: $_messageCount',
                      ),
                      const SizedBox(height: 8),
                      Text('Last handler: $_lastHandler'),
                      const SizedBox(height: 8),
                      Text('Message ID: $_messageId'),
                      const SizedBox(height: 8),
                      Text('Status: $_diagnostic'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Send a Firebase notification with custom '
                'data to update this screen.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
