import "package:flutter/material.dart";
import "package:juststockadmin/core/auth_session.dart";
import "package:juststockadmin/core/session_store.dart";
import "package:juststockadmin/features/admin/admin_overview_page.dart";
import "package:juststockadmin/features/admin/admin_pending_referrals_page.dart";
import "package:juststockadmin/features/admin/admin_users_page.dart";
import "package:juststockadmin/features/admin/admin_wallet_ledger_page.dart";
import "package:juststockadmin/features/admin/data/admin_api_service.dart";
import "package:juststockadmin/features/admin/data/admin_models.dart";
import "package:juststockadmin/features/admin/util/admin_formatters.dart";
import "package:juststockadmin/features/auth/sign_in_page.dart";

import "../../theme.dart";

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.adminName,
    required this.adminEmail,
  });

  final String adminName;
  final String adminEmail;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final AdminApiService _apiService;
  AdminOverviewStats? _stats;
  bool _loadingStats = false;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _apiService = AdminApiService();
    _loadStats();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });
    try {
      final overview = await _apiService.fetchOverview();
      if (!mounted) return;
      setState(() {
        _stats = overview.stats;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statsError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingStats = false;
        });
      }
    }
  }

  String _metricValue(String Function(AdminOverviewStats stats) builder) {
    final stats = _stats;
    if (stats != null) return builder(stats);
    if (_loadingStats) return "...";
    if (_statsError != null) return "--";
    return "...";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedName = widget.adminName.trim();
    final displayName = trimmedName.isEmpty ? 'Admin' : trimmedName;
    final initial = displayName.isEmpty ? 'A' : displayName[0].toUpperCase();
    final emailLabel = widget.adminEmail.trim().isEmpty
        ? 'Not provided'
        : widget.adminEmail.trim();
    final quickActionGradient = buildHeaderGradient();
    final quickActions = [
      _ProfileQuickAction(
        title: 'Dashboard overview',
        subtitle: 'Track signups, wallets and referrals.',
        icon: Icons.dashboard_customize_outlined,
        metric: _metricValue((stats) => "${stats.totalSignups}"),
        accentGradient: quickActionGradient,
        destinationBuilder: () => const AdminOverviewPage(),
      ),
      _ProfileQuickAction(
        title: 'Users directory',
        subtitle: 'Search accounts and see balances.',
        icon: Icons.people_alt_outlined,
        metric: _metricValue((stats) => "${stats.activeUsers}"),
        accentGradient: quickActionGradient,
        destinationBuilder: () => const AdminUsersPage(),
      ),
      _ProfileQuickAction(
        title: 'Wallet ledger',
        subtitle: 'Review credits, debits and payouts.',
        icon: Icons.account_balance_wallet_outlined,
        metric: _metricValue(
          (stats) => formatCurrency(stats.totalWalletBalance),
        ),
        accentGradient: quickActionGradient,
        destinationBuilder: () => const AdminWalletLedgerPage(),
      ),
      _ProfileQuickAction(
        title: 'Pending referrals',
        subtitle: 'Approve referral payouts in one place.',
        icon: Icons.card_giftcard_outlined,
        metric: _metricValue(
          (stats) => formatCurrency(stats.pendingReferralBalance),
        ),
        accentGradient: quickActionGradient,
        destinationBuilder: () => const AdminPendingReferralsPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: buildHeaderGradient()),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  gradient: buildHeaderGradient(),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(139, 0, 0, 0.22),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Admin Dashboard',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Contact details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: buildHeaderGradient(),
                        ),
                        child: const Icon(
                            Icons.email_outlined,
                            color: Colors.white,
                          ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Email address',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              emailLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Admin shortcuts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (_loadingStats)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              if (_statsError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unable to refresh dashboard metrics.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadStats,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 560;
                  final cardWidth = isWide
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final action in quickActions)
                        SizedBox(
                          width: cardWidth,
                          child: _ProfileQuickActionCard(
                            action: action,
                            onTap: () => _openAction(context, action.destinationBuilder),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAction(
    BuildContext context,
    Widget Function() destinationBuilder,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => destinationBuilder(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    AuthSession.clear();
    try {
      await SessionStore.clear();
    } catch (_) {}
    if (!navigator.mounted) {
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (context) => const SignInPage()),
      (route) => false,
    );
  }
}

class _ProfileQuickAction {
  const _ProfileQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.metric,
    required this.accentGradient,
    required this.destinationBuilder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String metric;
  final LinearGradient accentGradient;
  final Widget Function() destinationBuilder;
}

class _ProfileQuickActionCard extends StatelessWidget {
  const _ProfileQuickActionCard({
    required this.action,
    required this.onTap,
  });

  final _ProfileQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentGradient = action.accentGradient;
    final accentColors = accentGradient.colors;
    final accentColor = accentColors.isNotEmpty
        ? accentColors.last
        : theme.colorScheme.primary;
    final softenedGradient = accentColors.isNotEmpty
        ? LinearGradient(
            colors: accentColors
                .map((color) => color.withValues(alpha: 0.18))
                .toList(growable: false),
            begin: accentGradient.begin,
            end: accentGradient.end,
          )
        : LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.18),
              accentColor.withValues(alpha: 0.18),
            ],
            begin: accentGradient.begin,
            end: accentGradient.end,
          );

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: softenedGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      action.icon,
                      color: accentColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: softenedGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      action.metric,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                action.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'View details',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: accentColor,
                    size: 18,
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
