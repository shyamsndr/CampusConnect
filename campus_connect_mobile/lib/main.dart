import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';

/// Controls whether the Firebase Local Emulator Suite is used.
///
/// Defaults to true in debug builds, false in release builds.
/// Override at build time:
///   flutter run --dart-define=USE_FIREBASE_EMULATOR=false
const bool useFirebaseEmulator = bool.fromEnvironment(
  'USE_FIREBASE_EMULATOR',
  defaultValue: !kReleaseMode,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useFirebaseEmulator) {
    // Web/Chrome uses 127.0.0.1 to reach the host machine.
    // Android Emulator uses 10.0.2.2 to reach the host machine.
    // The Admin Chrome app uses 127.0.0.1 — both point to the same
    // emulator instance so they share the same Auth/Firestore data.
    const String host = kIsWeb ? '127.0.0.1' : '10.0.2.2';

    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);

    debugPrint('[Firebase] Emulator host: $host');
    debugPrint(
      '[Firebase] Connected to local Emulators '
      '(Auth: $host:9099, Firestore: $host:8080, Storage: $host:9199)',
    );
  } else {
    debugPrint(
      '[Firebase] Connected to Production Firebase '
      '(${DefaultFirebaseOptions.currentPlatform.projectId})',
    );
  }

  runApp(const CampusConnectApp());
}

class CampusConnectApp extends StatefulWidget {
  const CampusConnectApp({super.key});

  @override
  State<CampusConnectApp> createState() => _CampusConnectAppState();
}

class _CampusConnectAppState extends State<CampusConnectApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authService,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CampusConnect',
          theme: AppTheme.lightTheme,
          home: SplashScreen(authService: _authService),
        );
      },
    );
  }
}
