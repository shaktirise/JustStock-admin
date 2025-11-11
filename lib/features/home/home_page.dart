import "dart:convert";
import "dart:math" as math;

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;

import "package:juststockadmin/core/auth_session.dart";
import "package:juststockadmin/core/api_config.dart";
import "package:juststockadmin/core/http_client.dart" as http_client;
import "package:juststockadmin/core/session_store.dart";
import "package:juststockadmin/features/admin/admin_calls_page.dart";
import "package:juststockadmin/features/admin/admin_overview_page.dart";
import "package:juststockadmin/features/admin/admin_pending_referrals_page.dart";
import "package:juststockadmin/features/admin/admin_users_page.dart";
import "package:juststockadmin/features/admin/admin_wallet_ledger_page.dart";
import "package:juststockadmin/features/admin/admin_withdraw_requests_page.dart";
import "package:juststockadmin/features/profile/profile_page.dart";
// Removed dummy MLM Levels tool

import "../../theme.dart";

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.adminName,
    required this.adminEmail,
  });

  final String adminName;
  final String adminEmail;

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

  // New: Advice V2 quick actions (Stocks/Future/Options/Commodity)
  static const _adviceActions = <_AdviceCategoryAction>[
    _AdviceCategoryAction(label: 'Stocks', category: 'STOCKS', icon: Icons.auto_graph),
    _AdviceCategoryAction(label: 'Future', category: 'FUTURE', icon: Icons.trending_up),
    _AdviceCategoryAction(label: 'Options', category: 'OPTIONS', icon: Icons.swap_vert_circle_outlined),
    _AdviceCategoryAction(label: 'Commodity', category: 'COMMODITY', icon: Icons.analytics_outlined),
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
          adminEmail: widget.adminEmail,
        ),
      ),
    );
  }

  // Removed MLM page opener

  void _openAdminPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _handleAdviceComposeTap(_AdviceCategoryAction action) async {
    final result = await showModalBottomSheet<_AdviceComposeResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _AdviceComposeSheet(action: action),
    );

    if (!mounted || result == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
    );

    final outcome = await _sendAdviceV2(result);

    if (!mounted) return;
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) rootNavigator.pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(outcome.success ? 'Sent successfully.' : outcome.message)),
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

  Future<void> _openImageUploadSheet() async {
    final result = await showModalBottomSheet<_ImageUploadResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => const _ImageUploadSheet(),
    );

    if (!mounted || result == null) {
      return;
    }

    await _uploadImages(result);
  }

  Future<void> _openDailyTipSheet() async {
    final result = await showModalBottomSheet<_DailyTipSubmission>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => const _DailyTipSheet(),
    );

    if (!mounted || result == null) {
      return;
    }

    await _submitDailyTip(result);
  }

  Future<void> _uploadImages(_ImageUploadResult data) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    final uploadResult = await _sendImageUploadRequest(data);

    if (navigator.canPop()) {
      navigator.pop();
    }

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(uploadResult.message)));
  }

  Future<void> _submitDailyTip(_DailyTipSubmission data) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    final result = await _sendDailyTipRequest(data);

    if (navigator.canPop()) {
      navigator.pop();
    }

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<({bool success, String message})> _sendImageUploadRequest(
    _ImageUploadResult data,
  ) async {
    final uri = Uri.parse(
      'https://backend-server-11f5.onrender.com/api/images/upload',
    );

    final files = [for (final image in data.images) image.asApiPayload()];

    final Map<String, dynamic> payload;
    if (files.length == 1) {
      payload = {'file': files.first};
    } else {
      payload = {'files': files};
    }

    try {
      final http.Client client = http_client.buildHttpClient();
      try {
        final http.Response response = await client.post(
          uri,
          headers: AuthSession.withAuth({'Content-Type': 'application/json'}),
          body: jsonEncode(payload),
        );

        final decoded = _parseResponse(response.body);
        final isCreated = response.statusCode == 201;

        final message =
            decoded.message ??
            (isCreated
                ? 'Images uploaded successfully.'
                : 'Image upload failed. (HTTP ${response.statusCode})');

        if (isCreated) {
          try {
            await SessionStore.touchLastActivityNow();
          } catch (_) {}
          return (success: true, message: message);
        }

        return (success: false, message: message);
      } finally {
        try {
          client.close();
        } catch (_) {}
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to upload images: $error');
      debugPrint('$stackTrace');
      return (success: false, message: 'Network error. Please try again.');
    }
  }

  Future<({bool success, String message})> _sendDailyTipRequest(
    _DailyTipSubmission data,
  ) async {
    final uri = Uri.parse(
      'https://backend-server-11f5.onrender.com/api/admin/daily-tip',
    );

    final payload = {
      'message': data.message,
      'publishedAt': data.publishedAt.toUtc().toIso8601String(),
    };

    try {
      final http.Client client = http_client.buildHttpClient();
      try {
        final http.Response response = await client.post(
          uri,
          headers: AuthSession.withAuth({'Content-Type': 'application/json'}),
          body: jsonEncode(payload),
        );

        final decoded = _parseResponse(response.body);
        final bool isCreated = response.statusCode == 201;
        final bool success =
            decoded.success ?? (isCreated || response.statusCode == 200);
        final message =
            decoded.message ??
            (success
                ? 'Daily tip sent successfully.'
                : 'Unable to send daily tip.');

        if (success) {
          try {
            await SessionStore.touchLastActivityNow();
          } catch (_) {}
          return (success: true, message: message);
        }

        return (success: false, message: message);
      } finally {
        try {
          client.close();
        } catch (_) {}
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to submit daily tip: $error');
      debugPrint('$stackTrace');
      return (success: false, message: 'Network error. Please try again.');
    }
  }

  Future<void> _sendMessage({
    required _DashboardAction action,
    required String message,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
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
    final uri = Uri.parse(
      'https://backend-server-11f5.onrender.com/api/segments/$endpoint',
    );

    try {
      final http.Client client = http_client.buildHttpClient();
      try {
        final http.Response response = await client.post(
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
            (success
                ? 'Message sent successfully.'
                : 'Unable to send message.');

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

  Future<({bool success, String message})> _sendAdviceV2(
    _AdviceComposeResult data,
  ) async {
    // Map category to path as per API contract
    final String segment = () {
      switch (data.category.toUpperCase()) {
        case 'STOCKS':
          return 'stocks';
        case 'OPTIONS':
          return 'options';
        case 'FUTURE':
          return 'future';
        case 'COMMODITY':
          return 'commodity';
        default:
          return '';
      }
    }();

    final uri = segment.isEmpty
        ? AdminApiConfig.buildUri('/api/advice-v2')
        : AdminApiConfig.buildUri('/api/advice-v2/$segment');

    // Body spec: { text, price, buy, target, stoploss }
    final payload = <String, dynamic>{
      if (data.text != null && data.text!.trim().isNotEmpty) 'text': data.text!.trim(),
      if (data.buy != null && data.buy!.trim().isNotEmpty) 'buy': data.buy!.trim(),
      if (data.target != null && data.target!.trim().isNotEmpty) 'target': data.target!.trim(),
      if (data.stoploss != null && data.stoploss!.trim().isNotEmpty) 'stoploss': data.stoploss!.trim(),
      if (data.price != null) 'price': data.price,
    };

    try {
      final http.Client client = http_client.buildHttpClient();
      try {
        final response = await client
            .post(
              uri,
              headers: AuthSession.withAuth({'Content-Type': 'application/json'}),
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 25));

        final decoded = _parseResponse(response.body);
        final success = decoded.success ??
            (response.statusCode >= 200 && response.statusCode < 300);
        final message = decoded.message ??
            (success ? 'Advice sent.' : 'Unable to send advice.');

        if (success) {
          try {
            await SessionStore.touchLastActivityNow();
          } catch (_) {}
          return (success: true, message: message);
        }
        return (success: false, message: message);
      } finally {
        try {
          client.close();
        } catch (_) {}
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to send advice-v2: $error');
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
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
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
              'Tap a segment icon to compose and send a message, or upload marketing images below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              alignment: WrapAlignment.start,
              children: [
                // New: Advice V2 actions (Stocks/Future/Options/Commodity)
                for (final action in HomePage._adviceActions)
                  _AdviceTile(
                    action: action,
                    onTap: () => _handleAdviceComposeTap(action),
                  ),
                // Removed legacy segment icons: Nifty, BankNifty, Stocks, Sensex, Commodity
                _UploadImagesTile(onTap: _openImageUploadSheet),
                _DailyTipTile(onTap: _openDailyTipSheet),
              ],
            ),
            const SizedBox(height: 32),
            // MLM section removed
            Text(
              'Admin management',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                const minTileWidth = 152.0;
                final availableWidth = constraints.maxWidth;
                final rawColumns =
                    (availableWidth + spacing) / (minTileWidth + spacing);
                final columns = math.max(1, rawColumns.floor());
                final tileWidth = columns == 1
                    ? availableWidth
                    : (availableWidth - (columns - 1) * spacing) / columns;

                final tiles = <Widget>[
                  _AdminShortcutTile(
                    icon: Icons.dashboard_outlined,
                    label: 'Overview',
                    onTap: () => _openAdminPage(const AdminOverviewPage()),
                  ),
                  _AdminShortcutTile(
                    icon: Icons.people_alt_outlined,
                    label: 'Users',
                    onTap: () => _openAdminPage(const AdminUsersPage()),
                  ),
                  _AdminShortcutTile(
                    icon: Icons.call_made_outlined,
                    label: 'Calls',
                    onTap: () => _openAdminPage(const AdminCallsPage()),
                  ),
                  _AdminShortcutTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet ledger',
                    onTap: () => _openAdminPage(const AdminWalletLedgerPage()),
                  ),
                  _AdminShortcutTile(
                    icon: Icons.card_giftcard_outlined,
                    label: 'Referrals',
                    onTap: () =>
                        _openAdminPage(const AdminPendingReferralsPage()),
                  ),
                  _AdminShortcutTile(
                    icon: Icons.payments_outlined,
                    label: 'Withdraw requests',
                    onTap: () => _openAdminPage(const AdminWithdrawRequestsPage()),
                  ),
                ];

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final tile in tiles)
                      SizedBox(width: tileWidth, child: tile),
                  ],
                );
              },
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
                errorText: _showValidationError
                    ? 'Please add a message.'
                    : null,
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

// ===== Advice V2 Compose =====
class _AdviceCategoryAction {
  const _AdviceCategoryAction({
    required this.label,
    required this.category,
    required this.icon,
  });
  final String label;
  final String category; // canonical required by backend: STOCKS/FUTURE/OPTIONS/COMMODITY
  final IconData icon;
}

class _AdviceComposeResult {
  const _AdviceComposeResult({
    required this.category,
    this.text,
    this.buy,
    this.target,
    this.stoploss,
    this.price,
  });
  final String category;
  final String? text;
  final String? buy;
  final String? target;
  final String? stoploss;
  final int? price; // rupees
}

class _AdviceComposeSheet extends StatefulWidget {
  const _AdviceComposeSheet({required this.action});
  final _AdviceCategoryAction action;

  @override
  State<_AdviceComposeSheet> createState() => _AdviceComposeSheetState();
}

class _AdviceComposeSheetState extends State<_AdviceComposeSheet> {
  late final TextEditingController _buy;
  late final TextEditingController _target;
  late final TextEditingController _stoploss;
  late final TextEditingController _text;
  late final TextEditingController _price;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _buy = TextEditingController();
    _target = TextEditingController();
    _stoploss = TextEditingController();
    _text = TextEditingController();
    _price = TextEditingController();
  }

  @override
  void dispose() {
    _buy.dispose();
    _target.dispose();
    _stoploss.dispose();
    _text.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _text.text.trim();
    final b = _buy.text.trim();
    final g = _target.text.trim();
    final s = _stoploss.text.trim();
    if ([t, b, g, s].every((e) => e.isEmpty)) {
      setState(() => _error = true);
      return;
    }
    int? price;
    final p = _price.text.trim();
    if (p.isNotEmpty) price = int.tryParse(p);
    Navigator.of(context).pop(
      _AdviceComposeResult(
        category: widget.action.category,
        text: t.isEmpty ? null : t,
        buy: b.isEmpty ? null : b,
        target: g.isEmpty ? null : g,
        stoploss: s.isEmpty ? null : s,
        price: price,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                  'Send ${widget.action.label} advice',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _buy,
              decoration: const InputDecoration(labelText: 'BUY'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _target,
              decoration: const InputDecoration(labelText: 'TARGET'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stoploss,
              decoration: const InputDecoration(labelText: 'STOPLOSS'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _text,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Message (optional)',
                hintText: 'If empty, BUY/TARGET/STOPLOSS are combined',
                errorText: _error ? 'Enter message or at least one of BUY/TARGET/STOPLOSS' : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (₹, optional, default 116)',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyTipSubmission {
  const _DailyTipSubmission({required this.message, required this.publishedAt});

  final String message;
  final DateTime publishedAt;
}

class _DailyTipSheet extends StatefulWidget {
  const _DailyTipSheet();

  @override
  State<_DailyTipSheet> createState() => _DailyTipSheetState();
}

class _DailyTipSheetState extends State<_DailyTipSheet> {
  late final TextEditingController _messageController;
  late DateTime _scheduledFor;
  bool _showValidationError = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _scheduledFor = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final initialDate = _scheduledFor;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _scheduledFor = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _scheduledFor.hour,
        _scheduledFor.minute,
      );
    });
  }

  Future<void> _selectTime() async {
    final timeOfDay = TimeOfDay.fromDateTime(_scheduledFor);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: timeOfDay,
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _scheduledFor = DateTime(
        _scheduledFor.year,
        _scheduledFor.month,
        _scheduledFor.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _setPublishNow() {
    final now = DateTime.now();
    setState(() {
      _scheduledFor = now;
    });
  }

  void _handleSubmit() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _showValidationError = true);
      return;
    }

    Navigator.of(
      context,
    ).pop(_DailyTipSubmission(message: message, publishedAt: _scheduledFor));
  }

  Widget _buildSchedulePicker({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final localizations = MaterialLocalizations.of(context);
    final timeOfDay = TimeOfDay.fromDateTime(_scheduledFor);
    final timeLabel = localizations.formatTimeOfDay(
      timeOfDay,
      alwaysUse24HourFormat: mediaQuery.alwaysUse24HourFormat,
    );
    final dateLabel = localizations.formatMediumDate(_scheduledFor);

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
                  child: const Icon(
                    Icons.tips_and_updates_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Send daily tip',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Tip message',
                hintText: 'Share the daily motivation or market insight',
                errorText: _showValidationError
                    ? 'Please add a tip message.'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Publish schedule',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSchedulePicker(
                    icon: Icons.calendar_month_outlined,
                    label: 'Date',
                    value: dateLabel,
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSchedulePicker(
                    icon: Icons.schedule_outlined,
                    label: 'Time',
                    value: timeLabel,
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _setPublishNow,
                child: const Text('Use current time'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                child: const Text('Send tip'),
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

class _AdviceTile extends StatelessWidget {
  const _AdviceTile({required this.action, required this.onTap});

  final _AdviceCategoryAction action;
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
          child: _AdviceBadge(action: action),
        ),
      ),
    );
  }
}

class _AdviceBadge extends StatelessWidget {
  const _AdviceBadge({required this.action});

  final _AdviceCategoryAction action;

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
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(139, 0, 0, 0.25),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              action.icon,
              color: theme.colorScheme.onPrimary,
              size: 28,
            ),
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

class _ImageUploadSheet extends StatefulWidget {
  const _ImageUploadSheet();

  @override
  State<_ImageUploadSheet> createState() => _ImageUploadSheetState();
}

class _ImageUploadSheetState extends State<_ImageUploadSheet> {
  final List<_PendingImage> _images = <_PendingImage>[];
  bool _showImageError = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = 3 - _images.length;
    if (remaining <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload up to 3 images.')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: remaining > 1,
        withData: true,
        type: FileType.image,
      );

      if (result == null) {
        return;
      }

      final selected = <_PendingImage>[];
      for (final file in result.files) {
        if (selected.length >= remaining) {
          break;
        }
        final bytes = file.bytes;
        if (bytes == null) {
          continue;
        }

        selected.add(
          _PendingImage(
            name: file.name,
            base64Data: base64Encode(bytes),
            sizeInBytes: bytes.length,
            mimeType: _inferMimeType(file.name),
          ),
        );
      }

      if (selected.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read selected images.')),
        );
        return;
      }

      setState(() {
        _images.addAll(selected);
        _showImageError = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to pick images: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick images. Please try again.'),
        ),
      );
    }
  }

  void _removeImage(_PendingImage image) {
    setState(() {
      _images.remove(image);
    });
  }

  void _submit() {
    if (_images.isEmpty) {
      setState(() => _showImageError = true);
      return;
    }

    Navigator.of(context).pop(
      _ImageUploadResult(images: List<_PendingImage>.unmodifiable(_images)),
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  String? _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload images',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose up to three images. Selected files upload to Cloudinary once you continue.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(
                _images.isEmpty ? 'Select images (max 3)' : 'Add more images',
              ),
            ),
            if (_showImageError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select at least one image.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_images.isNotEmpty) ...[
              ..._images.map(
                (image) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          image.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatSize(image.sizeInBytes),
                        style: theme.textTheme.bodySmall,
                      ),
                      IconButton(
                        tooltip: 'Remove image',
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeImage(image),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Upload images'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageUploadResult {
  const _ImageUploadResult({required this.images});

  final List<_PendingImage> images;
}

class _PendingImage {
  const _PendingImage({
    required this.name,
    required this.base64Data,
    required this.sizeInBytes,
    this.mimeType,
  });

  final String name;
  final String base64Data;
  final int sizeInBytes;
  final String? mimeType;

  String asApiPayload() {
    final type = mimeType;
    if (type == null || type.isEmpty) {
      return base64Data;
    }
    return 'data:$type;base64,$base64Data';
  }
}

class _DailyTipTile extends StatelessWidget {
  const _DailyTipTile({required this.onTap});

  final VoidCallback onTap;

  static const _DashboardAction _visual = _DashboardAction(
    label: 'Daily Tip',
    icon: Icons.tips_and_updates_outlined,
    endpoint: 'admin/daily-tip',
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Send daily tip',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: _ActionBadge(action: _visual),
        ),
      ),
    );
  }
}

class _UploadImagesTile extends StatelessWidget {
  const _UploadImagesTile({required this.onTap});

  final VoidCallback onTap;

  static const _DashboardAction _visual = _DashboardAction(
    label: 'Upload',
    icon: Icons.cloud_upload_outlined,
    endpoint: 'images/upload',
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Upload images',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: _ActionBadge(action: _visual),
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
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(139, 0, 0, 0.25),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              action.icon,
              color: theme.colorScheme.onPrimary,
              size: 28,
            ),
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

class _MlmShortcut extends StatelessWidget {
  const _MlmShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          gradient: buildHeaderGradient(),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(139, 0, 0, 0.25),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  color: theme.colorScheme.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MLM Levels',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View level progress and open each layer in a dropdown tree.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminShortcutTile extends StatelessWidget {
  const _AdminShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Open',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
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
