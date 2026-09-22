import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'package:flutter/foundation.dart';
import 'splash/splash_controller.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("Background Notification Received:");
  print(message.notification?.title);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    await FCMService.initialize();
  }

  runApp(const JambooApp());
}

class JambooApp extends StatelessWidget {
  const JambooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Jamboo",
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _loaderController;

  @override
  void initState() {
    super.initState();

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SplashController.initialize(context);
    });
  }

  @override
  void dispose() {
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF4A148C),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/splash_background.png",
                fit: BoxFit.cover,
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 38,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 170,
                    height: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedBuilder(
                        animation: _loaderController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _SplashLoaderPainter(
                              progress: _loaderController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    "Getting things ready...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashLoaderPainter extends CustomPainter {
  final double progress;

  _SplashLoaderPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.fill;

    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        5,
      );

    final backgroundRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );

    canvas.drawRRect(
      backgroundRect,
      backgroundPaint,
    );

    const segmentWidth = 55.0;

    final startX =
        (size.width + segmentWidth) * progress -
        segmentWidth;

    final glowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        startX,
        0,
        segmentWidth,
        size.height,
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(
      glowRect,
      glowPaint,
    );

    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        startX,
        0,
        segmentWidth,
        size.height,
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(
      progressRect,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(
    _SplashLoaderPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}