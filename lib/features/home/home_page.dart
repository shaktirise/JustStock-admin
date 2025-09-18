import "dart:convert";

import "package:flutter/material.dart";
import "package:juststockadmin/core/http_client.dart" as http_client;
import "package:http/http.dart" as http;

import "package:juststockadmin/features/profile/profile_page.dart";
import "../../theme.dart";
import "package:juststockadmin/core/auth_session.dart";

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.adminName,
    required this.adminMobile,
  });

  final String adminName;
  final String adminMobile;

  static const _actions = <_DashboardAction>[
    _DashboardAction(
      label: 'Nifty',
      icon: Icons.trending_up,
      endpoint: 'nifty',
    ),
    _DashboardAction(
      label: 'BankNifty',
      icon: Icons.account_balance,
      endpoint: 'banknifty',
    ),
    _DashboardAction(label: 'Stocks', icon: Icons.insights, endpoint: 'stocks'),
    _DashboardAction(
      label: 'Sensex',
      icon: Icons.show_chart,
      endpoint: 'sensex',
    ),
    _DashboardAction(
      label: 'Commodity',
      icon: Icons.auto_graph,
      endpoint: 'commodity',
    ),
  ];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final List<TextEditingController> _controllers;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      HomePage._actions.length,
      (_) => TextEditingController(),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfilePage(
          adminName: widget.adminName,
          adminMobile: widget.adminMobile,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final pendingMessages = <int, String>{};
    for (var index = 0; index < HomePage._actions.length; index++) {
      final message = _controllers[index].text.trim();
      if (message.isNotEmpty) {
        pendingMessages[index] = message;
      }
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (pendingMessages.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please add a message before submitting.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final successfulSegments = <String>[];
    final failedSegments = <String>[];

    for (final entry in pendingMessages.entries) {
      final index = entry.key;
      final action = HomePage._actions[index];
      final result = await _sendSegmentMessage(
        endpoint: action.endpoint,
        message: entry.value,
      );

      if (result.success) {
        successfulSegments.add(action.label);
        _controllers[index].clear();
      } else {
        failedSegments.add('${action.label}: ${result.message}');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    final feedbackMessages = <String>[];
    if (successfulSegments.isNotEmpty) {
      feedbackMessages.add(
        'Sent updates for ${successfulSegments.join(', ')}.',
      );
    }
    if (failedSegments.isNotEmpty) {
      feedbackMessages.add('Failed to send: ${failedSegments.join('; ')}');
    }

    final snackMessage = feedbackMessages.join(' ');

    scaffoldMessenger.showSnackBar(SnackBar(content: Text(snackMessage)));
  }

  Future<({bool success, String message})> _sendSegmentMessage({
    required String endpoint,
    required String message,
  }) async {
    final uri = Uri.parse(
      'https://juststock.onrender.com/api/segments/$endpoint',
    );

    try {
      final client = http_client.buildHttpClient();
      try {
        final response = await client.post(
        uri,
        headers: AuthSession.withAuth({'Content-Type': 'application/json'}),
        body: jsonEncode({'message': message}),
      );

      final decoded = _parseResponse(response.body);
      final success =
          decoded.success ??
          (response.statusCode >= 200 && response.statusCode < 300);
      final serverMessage =
          decoded.message ??
          (success ? 'Message sent successfully.' : 'Unable to send message.');

      return (success: success, message: serverMessage);
    } finally {
      try { client.close(); } catch (_) {}
    }
    } catch (error, stackTrace) {
      debugPrint('Failed to send segment message (' + endpoint + '): $error');
      debugPrint('$stackTrace');
      return (success: false, message: 'Network error. Please try again.');
    }
  }

  ({bool? success, String? message}) _parseResponse(String body) {
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
          } else if (normalized == 'error' ||
              normalized == 'failed' ||
              normalized == 'failure') {
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

        return (success: success, message: message);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to parse response body: $error');
      debugPrint('$stackTrace');
    }
    return (success: null, message: null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedName = widget.adminName.trim();
    final displayName = trimmedName.isEmpty ? 'Admin' : trimmedName;
    final initial = displayName[0].toUpperCase();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 88,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'JustStock',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Admin Dashboard',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Semantics(
              label: 'Open profile',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openProfile,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: buildHeaderGradient()),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $displayName!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitor live market segments and manage investor communications.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              HomePage._actions.length,
              (index) => Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 16),
                child: _ActionMessageRow(
                  action: HomePage._actions[index],
                  controller: _controllers[index],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _handleSubmit(),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ActionMessageRow extends StatelessWidget {
  const _ActionMessageRow({required this.action, required this.controller});

  final _DashboardAction action;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionBadge(action: action),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '${action.label} message',
              hintText: 'Enter update for ${action.label}',
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              gradient: buildHeaderGradient(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(255, 152, 0, 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(action.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            action.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.label,
    required this.icon,
    required this.endpoint,
  });

  final String label;
  final IconData icon;
  final String endpoint;
}
