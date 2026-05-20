import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/role_utils.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/validation_message.dart';
import 'landing_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  static const String routeName = '/signup';

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = RoleUtils.jobSeeker;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static final RegExp _emailPattern = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d).{6,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    if (!_passwordPattern.hasMatch(value)) {
      return 'Use at least 6 characters with letters and numbers.';
    }
    return null;
  }

  bool _validateForm() {
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    setState(() {
      _emailError = _validateEmail(_emailController.text.trim());
      _passwordError = _validatePassword(password);
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Please confirm your password.';
      } else if (confirmPassword != password) {
        _confirmPasswordError = 'Passwords do not match.';
      } else {
        _confirmPasswordError = null;
      }
    });

    return _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  Future<void> _signup() async {
    if (!_validateForm()) {
      _showMessage('Please fix the highlighted fields.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    try {
      RoleUtils.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      _showMessage('Could not create account. Please try again.', isError: true);
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    _showMessage('Account created as $_selectedRole. Please sign in.');
    Navigator.pushReplacementNamed(context, LoginPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Create your account',
      subtitle: 'Join as a job seeker or employer. Admin access is managed by our team.',
      onBack: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, LandingPage.routeName);
        }
      },
      footer: TextButton(
        onPressed: () => Navigator.pushReplacementNamed(context, LoginPage.routeName),
        child: const Text('Already have an account? Sign in'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'I am joining as',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool stack = constraints.maxWidth < 400;
              final List<Widget> roleCards = RoleUtils.publicSignupRoles
                  .map((String role) => Expanded(child: _RoleCard(
                        role: role,
                        selected: _selectedRole == role,
                        onTap: () => setState(() => _selectedRole = role),
                      )))
                  .toList();

              if (stack) {
                return Column(
                  children: RoleUtils.publicSignupRoles
                      .map(
                        (String role) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RoleCard(
                            role: role,
                            selected: _selectedRole == role,
                            onTap: () => setState(() => _selectedRole = role),
                          ),
                        ),
                      )
                      .toList(),
                );
              }

              return Row(children: roleCards);
            },
          ),
          const SizedBox(height: 24),
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
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          ValidationMessage(message: _passwordError),
          const SizedBox(height: 16),
          CommonTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm password',
            obscureText: _obscureConfirm,
            hasError: _confirmPasswordError != null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          ValidationMessage(message: _confirmPasswordError),
          const SizedBox(height: 24),
          CommonButton(
            label: _isSubmitting ? 'Creating account…' : 'Create account',
            icon: Icons.person_add_outlined,
            onPressed: _isSubmitting ? null : _signup,
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final String role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSeeker = role == RoleUtils.jobSeeker;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.indigo.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.indigo : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              Icon(
                isSeeker ? Icons.person_search_outlined : Icons.business_center_outlined,
                color: selected ? AppColors.indigo : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                role,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.indigo : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
