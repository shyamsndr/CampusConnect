import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/services/admin_repository.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth/admin_login_screen.dart';
import 'widgets/navigation/admin_layout.dart';

/// Controls whether local Firebase Emulators are used.
/// Defaults to true during development (!kReleaseMode), and false in production builds.
/// Can be overridden explicitly:
///   flutter run -d chrome --dart-define=USE_FIREBASE_EMULATOR=false
///   flutter run -d chrome --dart-define=USE_FIREBASE_EMULATOR=true
const bool useFirebaseEmulator = bool.fromEnvironment(
  'USE_FIREBASE_EMULATOR',
  defaultValue: !kReleaseMode,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useFirebaseEmulator) {
    // Connect to Firebase Local Emulator Suite on localhost (127.0.0.1) for Chrome Web
    const String host = '127.0.0.1';
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFunctions.instanceFor(region: 'us-central1').useFunctionsEmulator(host, 5001);
    debugPrint('[Firebase] Connected to local Emulators '
        '(Auth: $host:9099, Firestore: $host:8080, Functions: $host:5001)');
  } else {
    debugPrint('[Firebase] Connected to Production Firebase '
        '(${DefaultFirebaseOptions.currentPlatform.projectId})');
  }

  runApp(const CampusConnectAdminApp());
}

/// CampusConnect Web Administration Application.
class CampusConnectAdminApp extends StatefulWidget {
  const CampusConnectAdminApp({super.key});

  @override
  State<CampusConnectAdminApp> createState() => _CampusConnectAdminAppState();
}

class _CampusConnectAdminAppState extends State<CampusConnectAdminApp> {
  late final AdminRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = AdminRepository();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        return MaterialApp(
          title: 'CampusConnect Admin Portal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: _repository.isInitializing
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _repository.isAuthenticated
              ? AdminLayout(repository: _repository)
              : AdminLoginScreen(repository: _repository),
        );
      },
    );
  }
}
