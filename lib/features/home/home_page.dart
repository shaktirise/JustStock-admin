import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

import "package:juststockadmin/core/auth_session.dart";
import "package:juststockadmin/core/http_client.dart" as http_client;
import "package:juststockadmin/core/session_store.dart";
import "package:juststockadmin/features/profile/profile_page.dart";

import "../../theme.dart";

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
    _DashboardAction(
      label: 'Stocks',
      icon: Icons.insights,
      endpoint: 'stocks',
    ),
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

  Future<void> _handleComposeTap(_DashboardAction action) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _ComposeMessageSheet(action: action),
    );

    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }

    await _sendMessage(action: action, message: message.trim());
  }

  Future<void> _sendMessage({
    required _DashboardAction action,
    required String message,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _sendSegmentMessage(
      endpoint: action.endpoint,
      message: message,
    );

    if (!mounted) {
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '${action.label} sent successfully.'
              : result.message,
        ),
      ),
    );
  }

  Future<({bool success, String message})> _sendSegmentMessage({
    required String endpoint,
    required String message,
  }) async {
    final uri = Uri.parse('https://juststock.onrender.com/api/segments/$endpoint');

    try {
      final http.Client client = http_client.buildHttpClient();
      try {
        final http.Response response = await client.post(
          uri,
          headers: AuthSession.withAuth({'Content-Type': 'application/json'}),
          body: jsonEncode({'message': message}),
        );

        final decoded = _parseResponse(response.body);
        final success = decoded.success ??
            (response.statusCode >= 200 && response.statusCode < 300);
        final serverMessage = decoded.message ??
            (success ? 'Message sent successfully.' : 'Unable to send message.');

        if (success) {
          try {
            await SessionStore.touchLastActivityNow();
          } catch (_) {}
        }

        return (success: success, message: serverMessage);
      } finally {
        try {
          client.close();
        } catch (_) {}
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to send segment message ($endpoint): $error');
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
              'Tap a segment icon to compose and send a message.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final action in HomePage._actions)
                  _ActionTile(
                    action: action,
                    onTap: () => _handleComposeTap(action),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposeMessageSheet extends StatefulWidget {
  const _ComposeMessageSheet({required this.action});

  final _DashboardAction action;

  @override
  State<_ComposeMessageSheet> createState() => _ComposeMessageSheetState();
}

class _ComposeMessageSheetState extends State<_ComposeMessageSheet> {
  late final TextEditingController _controller;
  bool _showValidationError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _showValidationError = true);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: buildHeaderGradient(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.action.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  'Compose for ${widget.action.label}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '${widget.action.label} message',
                hintText: 'Enter update for ${widget.action.label}',
                errorText:
                    _showValidationError ? 'Please add a message.' : null,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});

  final _DashboardAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open compose for ${action.label}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: _ActionBadge(action: action),
        ),
      ),
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
