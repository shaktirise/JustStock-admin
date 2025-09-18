import "dart:convert";

import "package:flutter/material.dart";
import "package:juststockadmin/core/http_client.dart" as http_client;
import "package:http/http.dart" as http;
import "package:juststockadmin/features/home/home_page.dart";

import "../../theme.dart";
import "package:juststockadmin/core/auth_session.dart";`nimport "package:juststockadmin/core/session_store.dart";

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isSending = false;

  static final Uri _requestOtpUri = Uri.parse('https://juststock.onrender.com/api/auth/admin/requestOtp');
  static final Uri _verifyOtpUri = Uri.parse('https://juststock.onrender.com/api/auth/admin/verifyOtp');

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (_isSending) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
    });

    final name = _nameController.text.trim();
    final phone = _buildE164Phone(_mobileController.text);

    final result = await _requestOtp(name: name, phone: phone);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );

    if (result.success) {
      await _promptForOtp();
    }
  }

  Future<({bool success, String message, Map<String, dynamic>? data})> _requestOtp({
    required String name,
    required String phone,
  }) async {
    try {
      final client = http_client.buildHttpClient();
      try {
        final response = await client.post(
        _requestOtpUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
        }),
      );

      final decoded = _decodeBody(response.body);
      final success =
          decoded.success ?? (response.statusCode >= 200 && response.statusCode < 300);
      final message = decoded.message ??
          (success ? 'OTP sent successfully.' : 'Failed to send OTP. Please try again.');

      return (success: success, message: message, data: decoded.data);
    } finally {
      try { client.close(); } catch (_) {}
    }
    } catch (error, stackTrace) {
      debugPrint('Failed to request OTP: $error');
      debugPrint('$stackTrace');
      return (
        success: false,
        message: 'Unable to send OTP. Check your connection and try again.',
        data: null,
      );
    }
  }

  Future<({bool success, String message, Map<String, dynamic>? data})> _verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final client = http_client.buildHttpClient();
      try {
        final response = await client.post(
        _verifyOtpUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
        }),
      );

      final decoded = _decodeBody(response.body);
      final success =
          decoded.success ?? (response.statusCode >= 200 && response.statusCode < 300);
      final message = decoded.message ??
          (success ? 'OTP verified successfully.' : 'Invalid OTP. Please try again.');

      return (success: success, message: message, data: decoded.data);
    } finally {
      try { client.close(); } catch (_) {}
    }
    } catch (error, stackTrace) {
      debugPrint('Failed to verify OTP: $error');
      debugPrint('$stackTrace');
      return (
        success: false,
        message: 'Unable to verify OTP. Check your connection and try again.',
        data: null,
      );
    }
  }

  ({bool? success, String? message, Map<String, dynamic>? data}) _decodeBody(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        bool? success;
        final successValue = decoded['success'];
        if (successValue is bool) {
          success = successValue;
        }
        final okValue = decoded['ok'];
        if (success == null && okValue is bool) {
          success = okValue;
        }
        final statusValue = decoded['status'];
        if (success == null && statusValue is String) {
          final normalized = statusValue.toLowerCase();
          if (normalized == 'success' || normalized == 'ok') {
            success = true;
          } else if (normalized == 'error' || normalized == 'failed' || normalized == 'failure') {
            success = false;
          }
        }

        String? message;
        for (final key in ['message', 'msg', 'error', 'detail', 'status']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            message = value;
            break;
          }
        }

        return (
          success: success,
          message: message,
          data: decoded,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to decode response body: $error');
      debugPrint('$stackTrace');
    }
    return (success: null, message: null, data: null);
  }

  String _buildE164Phone(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (trimmed.startsWith('+')) {
      return trimmed;
    }
    return '+91$trimmed';
  }

  Future<void> _promptForOtp() async {
    _otpController.clear();
    String? errorText;
    String? successMessage;
    bool isVerifying = false;
    final phone = _buildE164Phone(_mobileController.text);

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Verify OTP'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the 6-digit code sent to $phone.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'One-Time Password',
                      counterText: '',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final enteredOtp = _otpController.text.trim();
                          if (enteredOtp.length != 6) {
                            setLocalState(() {
                              errorText = 'Please enter the 6-digit OTP sent to your phone.';
                            });
                            return;
                          }

                          setLocalState(() {
                            isVerifying = true;
                            errorText = null;
                          });

                          final result = await _verifyOtp(
                            phone: phone,
                            otp: enteredOtp,
                          );

                          setLocalState(() {
                            isVerifying = false;
                          });

                          if (!mounted) {
                            return;
                          }

                          if (result.success) {
                            final data = result.data;
                            String? token;
                            if (data != null) {
                              final dynamic t1 = data['token'];
                              final dynamic t2 = data['accessToken'];
                              final dynamic t3 = data['access_token'];
                              final dynamic t4 = data['jwt'];
                              final dynamic t5 = data['sessionToken'];
                              token = [t1, t2, t3, t4, t5]
                                  .whereType<String>()
                                  .firstWhere((s) => s.isNotEmpty, orElse: () => '');
                            }
                            if (token != null && token.isNotEmpty) {
                              AuthSession.adminToken = token;\n                              try { await SessionStore.saveToken(token); } catch (_) {}
                            }
                            successMessage = result.message;
                            Navigator.of(dialogContext).pop(true);
                          } else {
                            setLocalState(() {
                              errorText = result.message;
                            });
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (verified ?? false) {
      if (successMessage != null && successMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage!),
          ),
        );
      }
      _navigateToHome();
    }
  }
  void _navigateToHome() {
    final trimmedName = _nameController.text.trim();
    final trimmedMobile = _mobileController.text.trim();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) =>
            HomePage(adminName: trimmedName, adminMobile: trimmedMobile),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 3) {
      return 'Name should be at least 3 characters';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Please enter your mobile number';
    }
    final numericOnly = RegExp(r'^\d{10}$');
    if (!numericOnly.hasMatch(trimmed)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  gradient: buildHeaderGradient(),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JustStock Admin',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Control your trading insights with a secure OTP check.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xD9FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign in',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your details to receive a verification code.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _validateName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mobileController,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            labelText: 'Mobile number',
                            prefixIcon: Icon(Icons.phone_outlined),
                            counterText: '',
                          ),
                          validator: _validateMobile,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isSending ? null : _handleSendOtp,
                          child: _isSending
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Send OTP'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
