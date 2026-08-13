import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/user_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase Init ──────────────────────────────────────────────────────────
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
    // On unsupported platforms or misconfiguration — surface a visible error
    runApp(_FirebaseErrorApp(error: e.toString()));
    return;
  }

  // ── System UI ─────────────────────────────────────────────────────────────
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // ── Repositories ──────────────────────────────────────────────────────────
  final authRepository = AuthRepository();
  final userRepository = UserRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthController(authRepository: authRepository, userRepository: userRepository),
        ),
      ],
      child: const ZabiraApp(),
    ),
  );
}

/// Shown only if Firebase fails to initialize (e.g. missing web config)
class _FirebaseErrorApp extends StatelessWidget {
  const _FirebaseErrorApp({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFD4AF37), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Configuration Error',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
