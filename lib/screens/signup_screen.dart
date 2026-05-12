import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/app_routes.dart';
import '../config/api_config.dart';
import '../theme/app_colors.dart';
import '../services/http_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  late final TextEditingController _householdIdController;

  String _userType = 'Representative';
  final String _selectedPlan = 'FREE';
  bool _acceptTerms = false;
  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String _error = '';
  String _success = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
    _householdIdController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _householdIdController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  int _getPlanCode(String planLabel) {
    return planLabel == 'PREMIUM' ? 2 : 1;
  }

  Future<void> _signUp() async {
    if (_isSubmitting) return;

    setState(() {
      _error = '';
      _success = '';
    });

    // Validations
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }

    if (!_validateEmail(_emailController.text)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    if (_userType == 'Representative' && !_acceptTerms) {
      setState(() => _error = 'You must accept the Terms & Privacy Policy.');
      return;
    }

    if (_userType == 'Representative') {
      await _confirmSignUp();
      return;
    }

    await _confirmSignUp();
  }

  Future<void> _confirmSignUp() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final normalizedEmail = _emailController.text.trim().toLowerCase();
      final normalizedPassword = _passwordController.text;
      final role = _userType == 'Member' ? 'Member' : 'Representative';
      final planCode = _getPlanCode(_selectedPlan);

      final _ = await HttpService(baseUrl: ApiConfig.baseUrl).post(
        '/api/v1/authentication/sign-up',
        body: {
          'email': normalizedEmail,
          'password': normalizedPassword,
          'name': _nameController.text,
          'role': role,
          'plan': planCode,
          'householdId': _userType == 'Member' ? _householdIdController.text.isEmpty ? null : _householdIdController.text : null,
        },
      );

      if (mounted) {
        setState(() {
          _success = 'Account created successfully. Redirecting to login...';
          _isSubmitting = false;
        });

        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          context.go(AppRoutes.login);
        }
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = err.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 40),
            child: Center(
              child: SizedBox(
                width: isMobile ? double.infinity : 390,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Budgetly',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'It only takes a minute to get started.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.labelGray,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error / Success Messages
                    if (_error.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_success.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _success,
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Account Type Toggle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Type',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _userType = 'Representative'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _userType == 'Representative'
                                          ? AppColors.teal
                                          : AppColors.borderGray,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(9),
                                    color: _userType == 'Representative'
                                        ? AppColors.teal.withOpacity(0.06)
                                        : AppColors.lightGray,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.home_outlined,
                                        size: 16,
                                        color: _userType == 'Representative'
                                            ? AppColors.teal
                                            : AppColors.textGray,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Representative',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _userType == 'Representative'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: _userType == 'Representative'
                                              ? AppColors.teal
                                              : AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _userType = 'Member'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _userType == 'Member'
                                          ? AppColors.teal
                                          : AppColors.borderGray,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(9),
                                    color: _userType == 'Member'
                                        ? AppColors.teal.withOpacity(0.06)
                                        : AppColors.lightGray,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 16,
                                        color: _userType == 'Member'
                                            ? AppColors.teal
                                            : AppColors.textGray,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Member',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _userType == 'Member'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: _userType == 'Member'
                                              ? AppColors.teal
                                              : AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    _buildLabel('Full Name'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _nameController,
                      placeholder: 'Jane Doe',
                      icon: Icons.person_outline,
                      autocomplete: 'name',
                    ),
                    const SizedBox(height: 14),

                    // Email
                    _buildLabel('Email'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _emailController,
                      placeholder: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      autocomplete: 'email',
                    ),
                    const SizedBox(height: 14),

                    // Password
                    _buildLabel('Password'),
                    const SizedBox(height: 6),
                    _buildPasswordField(
                      controller: _passwordController,
                      placeholder: 'At least 8 characters',
                      showPassword: _showPassword,
                      onToggle: () => setState(() => _showPassword = !_showPassword),
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password
                    _buildLabel('Confirm Password'),
                    const SizedBox(height: 6),
                    _buildPasswordField(
                      controller: _confirmController,
                      placeholder: 'Re-enter your password',
                      showPassword: _showConfirm,
                      onToggle: () => setState(() => _showConfirm = !_showConfirm),
                    ),
                    const SizedBox(height: 14),

                    // Household ID (Member only)
                    if (_userType == 'Member') ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Household ID',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                ),
                                TextSpan(
                                  text: ' (optional)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF9AB5BF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _householdIdController,
                            placeholder: 'Provided by your representative',
                            icon: Icons.home_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Terms (Representative only)
                    if (_userType == 'Representative') ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() => _acceptTerms = value ?? false);
                            },
                            activeColor: AppColors.teal,
                            side: const BorderSide(
                              color: AppColors.borderGray,
                              width: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGray,
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms',
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: null,
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: null,
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          disabledBackgroundColor: AppColors.teal.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.cream,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cream,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.borderGray.withOpacity(0.5),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.borderGray,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.borderGray.withOpacity(0.5),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Button
                    _buildSocialButton(
                      label: 'Continue with Google',
                      onPressed: () {},
                      icon: Icons.g_mobiledata,
                    ),
                    const SizedBox(height: 8),

                    // GitHub Button
                    _buildSocialButton(
                      label: 'Continue with GitHub',
                      onPressed: () {},
                      icon: Icons.code,
                    ),
                    const SizedBox(height: 18),

                    // Footer
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.labelGray,
                          ),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  context.go(AppRoutes.login);
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String autocomplete = '',
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: Icon(
          icon,
          color: AppColors.sky,
          size: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: AppColors.borderGray,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: AppColors.borderGray,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: AppColors.teal,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: AppColors.lightGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String placeholder,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
      decoration: InputDecoration(
        hintText: placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: AppColors.borderGray,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: AppColors.borderGray,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: AppColors.teal,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: AppColors.lightGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.sky,
            size: 18,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 11),
          side: const BorderSide(color: AppColors.borderGray, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.navy,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
