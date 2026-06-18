import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/validation_message.dart';
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
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus    = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool _isLoading = false;
  bool _obscurePassword = true;

  static final RegExp _emailPattern = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
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
      _formError = null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _login() async {
    if (!_validateForm()) {
      _showMessage('Please fix the highlighted fields.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _formError = null;
    });

    final String email = _emailController.text.trim();
    debugPrint('🔐 LoginPage: Attempting login for email=$email');

    final AuthResult result = await AuthService.instance.signIn(
      email: email,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (!result.success) {
      setState(() => _formError = result.message ?? 'Login failed.');
      _showMessage(result.message ?? 'Login failed.', isError: true);
      return;
    }

    final UserProfile? profile = result.profile;
    final String? routeName = result.routeName;

    debugPrint('🔐 LoginPage: Login successful');
    if (profile != null) {
      debugPrint('🔐 LoginPage: Profile - id=${profile.id}, email=${profile.email}, role=${profile.role}');
    }
    if (routeName != null) {
      debugPrint('🔐 LoginPage: Routing to $routeName');
    }

    if (profile == null || routeName == null || routeName.isEmpty) {
      setState(() {
        _formError =
            'Login succeeded but navigation data was missing. Please try again.';
      });
      _showMessage(_formError!, isError: true);
      return;
    }

    widget.onLoginSuccess();

    if (result.message != null && result.message!.isNotEmpty) {
      _showMessage(result.message!);
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (Route<dynamic> r) => false,
      arguments: result.routeArguments,
    );
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
            onPressed: _isLoading
                ? null
                : () => Navigator.pushNamed(context, SignupPage.routeName),
            child: const Text('New to Job For All? Create an account'),
          ),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Admin accounts are created in the Supabase dashboard, not via public signup.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_formError != null) ...<Widget>[
            _ErrorBanner(message: _formError!),
            const SizedBox(height: 16),
          ],
          CommonTextField(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            hasError: _emailError != null,
            enabled: !_isLoading,
            focusNode: _emailFocus,
            nextFocusNode: _passwordFocus,
            autofillHints: const <String>[AutofillHints.email],
          ),
          ValidationMessage(message: _emailError),
          const SizedBox(height: 16),
          CommonTextField(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: _obscurePassword,
            hasError: _passwordError != null,
            enabled: !_isLoading,
            focusNode: _passwordFocus,
            onSubmitted: _login,
            autofillHints: const <String>[AutofillHints.password],
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: _isLoading
                  ? null
                  : () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          ValidationMessage(message: _passwordError),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            )
          else
            CommonButton(
              label: 'Sign in',
              icon: Icons.login,
              onPressed: _login,
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}