import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/role_utils.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/validation_message.dart';
import 'home_page.dart';
import 'landing_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoginSuccess});

  static const String routeName = '/login';

  final VoidCallback onLoginSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showStaffLogin = false;

  static final RegExp _emailPattern = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'Email is required.';
    }
    if (!_emailPattern.hasMatch(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password is required.';
    }
    return null;
  }

  bool _validateForm() {
    setState(() {
      _emailError = _validateEmail(_emailController.text.trim());
      _passwordError = _validatePassword(_passwordController.text);
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _login() async {
    if (!_validateForm()) {
      _showMessage('Please fix the highlighted fields.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final bool loggedIn = RoleUtils.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (!loggedIn) {
      setState(() {
        _emailError = 'Invalid email or password.';
      });
      _showMessage(
        'Login failed. Check your credentials or create an account.',
        isError: true,
      );
      return;
    }

    widget.onLoginSuccess();
    _showMessage('Welcome back, ${RoleUtils.currentRole}.');
    Navigator.pushReplacementNamed(context, HomePage.routeName);
  }

  void _fillAdminDemo() {
    setState(() {
      _emailController.text = RoleUtils.adminDemoEmail;
      _passwordController.text = RoleUtils.adminDemoPassword;
      _showStaffLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Sign in',
      subtitle: 'Access your dashboard, applications, and job tools.',
      onBack: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, LandingPage.routeName);
        }
      },
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextButton(
            onPressed: () => Navigator.pushNamed(context, SignupPage.routeName),
            child: const Text('New to Job For All? Create an account'),
          ),
          const Divider(height: 32),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Platform staff sign in',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Admin accounts are created internally — not via public signup.',
              style: TextStyle(fontSize: 12),
            ),
            initiallyExpanded: _showStaffLogin,
            onExpansionChanged: (bool open) {
              setState(() => _showStaffLogin = open);
            },
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Demo admin (development)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Email: ${RoleUtils.adminDemoEmail}\n'
                      'Password: ${RoleUtils.adminDemoPassword}',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _fillAdminDemo,
                      child: const Text('Use demo admin credentials'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CommonTextField(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            hasError: _emailError != null,
          ),
          ValidationMessage(message: _emailError),
          const SizedBox(height: 16),
          CommonTextField(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: _obscurePassword,
            hasError: _passwordError != null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          ValidationMessage(message: _passwordError),
          const SizedBox(height: 24),
          CommonButton(
            label: _isLoading ? 'Signing in…' : 'Sign in',
            icon: Icons.login,
            onPressed: _isLoading ? null : _login,
          ),
        ],
      ),
    );
  }
}
