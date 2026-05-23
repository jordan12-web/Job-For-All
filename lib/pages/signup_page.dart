import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/role_utils.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/validation_message.dart';
import 'landing_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, this.onAuthSuccess});

  static const String routeName = '/signup';

  final VoidCallback? onAuthSuccess;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();

  String _selectedRole = RoleUtils.jobSeeker;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _companyNameError;
  String? _contactInfoError;
  String? _formError;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static final RegExp _emailPattern = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d).{6,}$',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _contactInfoController.dispose();
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

  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Full name is required.';
    }
    return null;
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

  String? _validateCompanyName(String value) {
    if (value.trim().isEmpty) {
      return 'Company name is required.';
    }
    return null;
  }

  String? _validateContactInfo(String value) {
    if (value.trim().isEmpty) {
      return 'Contact information is required.';
    }
    return null;
  }

  bool _validateForm() {
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    setState(() {
      _nameError = _validateName(_nameController.text);
      _emailError = _validateEmail(_emailController.text.trim());
      _passwordError = _validatePassword(password);
      _formError = null;
      
      // Validate role is selected
      if (_selectedRole.isEmpty) {
        _formError = 'Please select a role.';
      }
      
      // Validate employer-specific fields if employer is selected
      if (_selectedRole == RoleUtils.employer) {
        _companyNameError = _validateCompanyName(_companyNameController.text);
        _contactInfoError = _validateContactInfo(_contactInfoController.text);
      } else {
        _companyNameError = null;
        _contactInfoError = null;
      }
      
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Please confirm your password.';
      } else if (confirmPassword != password) {
        _confirmPasswordError = 'Passwords do not match.';
      } else {
        _confirmPasswordError = null;
      }
    });

    return _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _companyNameError == null &&
        _contactInfoError == null &&
        _formError == null;
  }

  Future<void> _signup() async {
    if (!_validateForm()) {
      _showMessage('Please fix the highlighted fields.', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String companyName = _companyNameController.text.trim();
    final String contactInfo = _contactInfoController.text.trim();
    
    debugPrint('🔐 SignupPage: Submitting signup with email=$email, name=$name, role=$_selectedRole');
    if (_selectedRole == RoleUtils.employer) {
      debugPrint('🔐 SignupPage: Employer metadata - company=$companyName, contact=$contactInfo');
    }

    final AuthResult result = await AuthService.instance.signUp(
      email: email,
      password: _passwordController.text,
      name: name,
      displayRole: _selectedRole,
      companyName: _selectedRole == RoleUtils.employer ? companyName : null,
      contactInfo: _selectedRole == RoleUtils.employer ? contactInfo : null,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!result.success) {
      setState(() => _formError = result.message ?? 'Signup failed.');
      _showMessage(result.message ?? 'Signup failed.', isError: true);
      return;
    }

    if (result.message != null && result.message!.isNotEmpty) {
      _showMessage(result.message!);
    }

    if (result.needsEmailConfirmation) {
      Navigator.pushReplacementNamed(context, LoginPage.routeName);
      return;
    }

    final UserProfile? profile = result.profile;
    final String? routeName = result.routeName;

    if (profile == null || routeName == null || routeName.isEmpty) {
      setState(() {
        _formError =
            'Account created but we could not open your dashboard. Please sign in.';
      });
      Navigator.pushReplacementNamed(context, LoginPage.routeName);
      return;
    }

    widget.onAuthSuccess?.call();
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
      title: 'Create your account',
      subtitle:
          'Register as a job seeker or employer. Admin access is managed separately.',
      onBack: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, LandingPage.routeName);
        }
      },
      footer: TextButton(
        onPressed: _isSubmitting
            ? null
            : () => Navigator.pushReplacementNamed(context, LoginPage.routeName),
        child: const Text('Already have an account? Sign in'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_formError != null) ...<Widget>[
            _ErrorBanner(message: _formError!),
            const SizedBox(height: 16),
          ],
          const Text(
            'I am joining as',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved to your account after registration completes.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool stack = constraints.maxWidth < 400;

              if (stack) {
                return Column(
                  children: RoleUtils.publicSignupRoles
                      .map(
                        (String role) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RoleCard(
                            role: role,
                            selected: _selectedRole == role,
                            onTap: _isSubmitting
                                ? () {}
                                : () => setState(() => _selectedRole = role),
                          ),
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: RoleUtils.publicSignupRoles
                    .map(
                      (String role) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _RoleCard(
                            role: role,
                            selected: _selectedRole == role,
                            onTap: _isSubmitting
                                ? () {}
                                : () => setState(() => _selectedRole = role),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          CommonTextField(
            controller: _nameController,
            labelText: 'Full name',
            hasError: _nameError != null,
            enabled: !_isSubmitting,
          ),
          ValidationMessage(message: _nameError),
          const SizedBox(height: 16),
          // Show employer fields only when employer role is selected
          if (_selectedRole == RoleUtils.employer) ...<Widget>[
            CommonTextField(
              controller: _companyNameController,
              labelText: 'Company name',
              hasError: _companyNameError != null,
              enabled: !_isSubmitting,
            ),
            ValidationMessage(message: _companyNameError),
            const SizedBox(height: 16),
            CommonTextField(
              controller: _contactInfoController,
              labelText: 'Contact information (email/phone)',
              hasError: _contactInfoError != null,
              enabled: !_isSubmitting,
            ),
            ValidationMessage(message: _contactInfoError),
            const SizedBox(height: 16),
          ],
          CommonTextField(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            hasError: _emailError != null,
            enabled: !_isSubmitting,
          ),
          ValidationMessage(message: _emailError),
          const SizedBox(height: 16),
          CommonTextField(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: _obscurePassword,
            hasError: _passwordError != null,
            enabled: !_isSubmitting,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          ValidationMessage(message: _passwordError),
          const SizedBox(height: 16),
          CommonTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm password',
            obscureText: _obscureConfirm,
            hasError: _confirmPasswordError != null,
            enabled: !_isSubmitting,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          ValidationMessage(message: _confirmPasswordError),
          const SizedBox(height: 24),
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            )
          else
            CommonButton(
              label: 'Create account',
              icon: Icons.person_add_outlined,
              onPressed: _signup,
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
                isSeeker
                    ? Icons.person_search_outlined
                    : Icons.business_center_outlined,
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
