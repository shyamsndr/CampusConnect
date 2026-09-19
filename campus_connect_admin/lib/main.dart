import 'package:flutter/material.dart';
import 'core/services/admin_repository.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/admin_login_screen.dart';
import 'widgets/navigation/admin_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
          home: _repository.isAuthenticated
              ? AdminLayout(repository: _repository)
              : AdminLoginScreen(repository: _repository),
        );
      },
    );
  }
}
