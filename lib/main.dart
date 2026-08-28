import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/audio/global_audio_controller.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/courses/presentation/controllers/enrollment_controller.dart';
import 'features/courses/presentation/controllers/wishlist_controller.dart';
import 'features/kids/presentation/controllers/kids_controller.dart';
import 'features/payment/presentation/controllers/payment_controller.dart';
import 'features/store/presentation/controllers/cart_controller.dart';
import 'features/student/presentation/controllers/student_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Optional Firebase Init ────────────────────────────────────────────────
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

  runApp(
    MultiProvider(
      providers: [
        // Global audio — must be first so all others can access it
        ChangeNotifierProvider(create: (_) => GlobalAudioController()),
        ChangeNotifierProvider(
          create: (_) => AuthController(authRepository: authRepository),
        ),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => EnrollmentController()),
        ChangeNotifierProvider(create: (_) => PaymentController()),
        ChangeNotifierProvider(create: (_) => StudentController()),
        ChangeNotifierProvider(create: (_) => KidsController()),
        ChangeNotifierProvider(create: (_) => WishlistController()),
      ],
      child: const ZabiraApp(),
    ),
  );
}
