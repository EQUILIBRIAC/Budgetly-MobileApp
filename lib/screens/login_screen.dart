import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _remember = false;
  bool _isSubmitting = false;
  String _error = '';
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    // Use centralized API configuration
    final httpService = HttpService(baseUrl: ApiConfig.baseUrl);
    _authService = AuthService(httpService: httpService);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isSubmitting) return;

    setState(() {
      _error = '';
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _error = 'Please fill in your email and password.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Save token and user data locally
      final token = _authService.lastToken;
      if (token != null) {
        await StorageService.saveToken(token);
      }
      
      await StorageService.saveUser({
        'id': user.id,
        'email': user.email,
        'role': user.role,
        'householdId': user.householdId,
        'isNewUser': user.isNewUser,
        'plan': user.plan,
      });

      if (mounted) {
        // Navigate based on role
        final target =
            user.role == 'member' ? 'member-dashboard' : 'representative-dashboard';

        Navigator.of(context).pushReplacementNamed(target);
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

  void _handleGoogleSignIn() {
    // TODO: Implement Google Sign-In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In coming soon')),
    );
  }

  void _handleGithubSignIn() {
    // TODO: Implement GitHub Sign-In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GitHub Sign-In coming soon')),
    );
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
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(9),
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
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Title
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to access your dashboard and continue managing your household.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.labelGray,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message
                    if (_error.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
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
                      const SizedBox(height: 16),
                    ],

                    // Email field
                    _buildLabel('Email'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
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
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    _buildLabel('Password'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
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
                            _showPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.sky,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Remember & Forgot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _remember = !_remember;
                            });
                          },
                          child: Row(
                            children: [
                              Checkbox(
                                value: _remember,
                                onChanged: (value) {
                                  setState(() {
                                    _remember = value ?? false;
                                  });
                                },
                                activeColor: AppColors.teal,
                                side: const BorderSide(
                                  color: AppColors.borderGray,
                                  width: 1.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed('forgot-password');
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 21),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _signIn,
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
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cream,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),

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
                    const SizedBox(height: 18),

                    // Google Button
                    _buildSocialButton(
                      label: 'Continue with Google',
                      onPressed: _handleGoogleSignIn,
                      icon: Icons.g_mobiledata,
                    ),
                    const SizedBox(height: 9),

                    // GitHub Button
                    _buildSocialButton(
                      label: 'Continue with GitHub',
                      onPressed: _handleGithubSignIn,
                      icon: Icons.code,
                    ),
                    const SizedBox(height: 21),

                    // Footer
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.labelGray,
                          ),
                          children: [
                            const TextSpan(text: 'Don\'t have an Account? '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed('signup');
                                },
                                child: const Text(
                                  'Sign Up',
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
