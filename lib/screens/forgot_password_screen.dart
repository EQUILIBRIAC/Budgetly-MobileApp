import 'package:flutter/material.dart';

import '../app/l10n/app_strings.dart';
import '../config/api_config.dart';
import '../services/http_service.dart';
import '../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitting = false;
  String _error = '';
  String _success = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _error = '';
      _success = '';
    });

    if (!_validEmail(email)) {
      setState(() => _error = AppStrings.forgotPasswordInvalidEmail);
      return;
    }

    setState(() => _submitting = true);
    try {
      await HttpService(baseUrl: ApiConfig.baseUrl).post(
        '/api/v1/authentication/forgot-password',
        body: {'email': email},
      );
      if (!mounted) return;
      setState(() {
        _success = AppStrings.forgotPasswordSuccess;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(AppStrings.forgotPasswordTitle),
        backgroundColor: AppColors.cream,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.forgotPasswordHint,
              style: TextStyle(color: AppColors.labelGray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            if (_success.isNotEmpty)
              Text(_success, style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.forgotPasswordSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
