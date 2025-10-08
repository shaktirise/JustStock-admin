import "package:flutter/material.dart";
import "package:juststockadmin/core/auth_session.dart";
import "package:juststockadmin/core/session_store.dart";
import "package:juststockadmin/features/admin/active_users_page.dart";
import "package:juststockadmin/features/admin/total_users_page.dart";
import "package:juststockadmin/features/admin/transaction_history_page.dart";
import "package:juststockadmin/features/auth/sign_in_page.dart";

import "../../theme.dart";

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.adminName,
    required this.adminMobile,
  });

  final String adminName;
  final String adminMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedName = adminName.trim();
    final displayName = trimmedName.isEmpty ? 'Admin' : trimmedName;
    final initial = displayName[0].toUpperCase();
    final mobileLabel = adminMobile.trim().isEmpty
        ? 'Not provided'
        : adminMobile.trim();
    final quickActionGradient = buildHeaderGradient();
    final quickActions = [
      _ProfileQuickAction(
        title: 'Total users logged in',
        subtitle: 'Review registrations and growth trends.',
        icon: Icons.groups_3_outlined,
        metric: '940',
        accentGradient: quickActionGradient,
        destinationBuilder: () => const TotalUsersPage(),
      ),
      _ProfileQuickAction(
        title: 'Active users',
        subtitle: 'See who is online right now.',
        icon: Icons.bolt_outlined,
        metric: '120',
        accentGradient: quickActionGradient,
        destinationBuilder: () => const ActiveUsersPage(),
      ),
      _ProfileQuickAction(
        title: 'Transaction history',
        subtitle: 'Track recent payouts and invoices.',
        icon: Icons.receipt_long_outlined,
        metric: '42',
        accentGradient: quickActionGradient,
        destinationBuilder: () => const TransactionHistoryPage(),
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
                          Icons.phone_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mobile number',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mobileLabel,
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
                .map((color) => color.withOpacity(0.18))
                .toList(growable: false),
            begin: accentGradient.begin,
            end: accentGradient.end,
          )
        : LinearGradient(
            colors: [
              accentColor.withOpacity(0.18),
              accentColor.withOpacity(0.18),
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
