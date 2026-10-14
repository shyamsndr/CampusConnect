import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../auth/login_screen.dart';
import '../main/main_screen.dart';

/// Screen for changing the user's password.
///
/// Used in two contexts:
///   1. **First-login forced change** — [isFirstLogin] is true. The user cannot
///      navigate away until they set a new password. On success the app navigates
///      to [MainScreen].
///   2. **Profile-initiated change** — [isFirstLogin] is false. On success the
///      screen pops back to the profile.
class ChangePasswordScreen extends StatefulWidget {
  final AuthService authService;
  final bool isFirstLogin;

  const ChangePasswordScreen({
    super.key,
    required this.authService,
    this.isFirstLogin = false,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter (A–Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter (a–z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one digit (0–9)';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$%...)';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _handleChangePassword() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await widget.authService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    _navigateOnSuccess();
  }

  void _navigateOnSuccess() {
    if (widget.isFirstLogin) {
      // Navigate to the main app and clear the stack.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(authService: widget.authService),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back navigation during first-login flow.
      canPop: !widget.isFirstLogin,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              // Blue header
              Container(
                height: 260,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    if (widget.isFirstLogin)
                      const Icon(
                        Icons.lock_reset_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    if (!widget.isFirstLogin)
                      const Icon(
                        Icons.lock_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    const SizedBox(height: 10),
                    Text(
                      widget.isFirstLogin
                          ? 'SET NEW PASSWORD'
                          : 'CHANGE PASSWORD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    if (widget.isFirstLogin)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Please set a new password to continue',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),

              // Form card
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 155,
                  left: 20,
                  right: 20,
                  bottom: 30,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 32, 22, 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildFormView(),
                ),
              ),

              // Back button (only for profile-initiated change)
              if (!widget.isFirstLogin)
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The normal form with Current Password, New Password, and Confirm fields.
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Password
          AuthTextField(
            label: 'Current Password',
            hint: '••••••••',
            obscureText: _obscureCurrent,
            controller: _currentPasswordController,
            validator: _validateCurrentPassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureCurrent = !_obscureCurrent;
                });
              },
              icon: Icon(
                _obscureCurrent
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 19,
                color: AppColors.textGrey,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // New Password
          AuthTextField(
            label: 'New Password',
            hint: '••••••••',
            obscureText: _obscureNew,
            controller: _newPasswordController,
            validator: _validateNewPassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureNew = !_obscureNew;
                });
              },
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 19,
                color: AppColors.textGrey,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Confirm New Password
          AuthTextField(
            label: 'Confirm New Password',
            hint: '••••••••',
            obscureText: _obscureConfirm,
            controller: _confirmPasswordController,
            validator: _validateConfirmPassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 19,
                color: AppColors.textGrey,
              ),
            ),
          ),

          const SizedBox(height: 32),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AuthButton(
                  text: 'UPDATE PASSWORD',
                  onPressed: _handleChangePassword,
                ),

          // Sign-out option during first login
          if (widget.isFirstLogin) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        await widget.authService.signOut();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(
                              authService: widget.authService,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
