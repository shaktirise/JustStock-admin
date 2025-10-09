import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:juststockadmin/core/http_client.dart" as http_client;

import "../../theme.dart";

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late final http.Client _httpClient;
  Future<void>? _warmupFuture;

  static final Uri _signupUri = Uri.parse(
    "https://backend-server-11f5.onrender.com/api/auth/admin/signup",
  );
  static final Uri _warmupUri = Uri.parse(
    "https://backend-server-11f5.onrender.com/",
  );
  static const Duration _requestTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _httpClient = http_client.buildHttpClient();
    _warmupFuture = _warmupBackend();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    try {
      _httpClient.close();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _warmupBackend() async {
    try {
      await _httpClient
          .get(
            _warmupUri,
            headers: const {"Cache-Control": "no-cache"},
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      debugPrint("Warmup request timed out.");
    } catch (error, stackTrace) {
      debugPrint("Warmup request failed: $error");
      debugPrint("$stackTrace");
    }
  }

  Future<void> _handleSignUp() async {
    if (_isSubmitting) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final messenger = ScaffoldMessenger.of(context);

    try {
      final warmup = _warmupFuture;
      if (warmup != null) {
        await warmup.catchError((_) {});
      }

      final response = await _httpClient
          .post(
            _signupUri,
            headers: const {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": name,
              "email": email,
              "password": password,
              "confirmPassword": confirmPassword,
            }),
          )
          .timeout(_requestTimeout);

      if (!mounted) return;

      final decoded = _decodeBody(response.body);
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final message = _extractMessage(decoded) ??
          (isSuccess
              ? "Account created successfully. Sign in to continue."
              : "Unable to create account.");

      if (!isSuccess) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      Navigator.of(context).pop((email: email, message: message));
    } on TimeoutException {
      messenger.showSnackBar(
        const SnackBar(content: Text("Signup timed out. Try again.")),
      );
    } catch (error, stackTrace) {
      debugPrint("Signup failed: $error");
      debugPrint("$stackTrace");
      messenger.showSnackBar(
        SnackBar(content: Text("Signup failed: $error")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (error, stackTrace) {
      debugPrint("Failed to decode signup response: $error");
      debugPrint("$stackTrace");
    }
    return const {};
  }

  String? _extractMessage(Map<String, dynamic> decoded) {
    final candidates = [
      decoded["message"],
      decoded["error"],
      decoded["status"],
      decoded["detail"],
      decoded["data"] is Map<String, dynamic>
          ? (decoded["data"] as Map<String, dynamic>)["message"]
          : null,
    ];

    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 24, 24, 32),
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
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Create admin account",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Register with your work email to access the JustStock admin tools.",
                      style: theme.textTheme.bodyMedium?.copyWith(
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
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Let's get started",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Provide your details to create an admin profile.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: "Full name",
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _validateName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          textInputAction: TextInputAction.next,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          textInputAction: TextInputAction.done,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: "Confirm password",
                            prefixIcon: const Icon(Icons.lock_person_outlined),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _validateConfirmPassword,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSignUp,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text("Create account"),
                          ),
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

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? "";
    if (trimmed.isEmpty) {
      return "Name is required";
    }
    if (trimmed.length < 3) {
      return "Name must be at least 3 characters";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? "";
    if (trimmed.isEmpty) {
      return "Email is required";
    }
    final emailRegex = RegExp(r"^[^@]+@[^@]+\.[^@]+$");
    if (!emailRegex.hasMatch(trimmed)) {
      return "Enter a valid email address";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Confirm your password";
    }
    if (value != _passwordController.text) {
      return "Passwords do not match";
    }
    return null;
  }
}
