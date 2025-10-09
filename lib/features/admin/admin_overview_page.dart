import "package:flutter/material.dart";

import "data/admin_api_service.dart";
import "data/admin_models.dart";
import "util/admin_formatters.dart";
import "admin_calls_page.dart";
import "admin_wallet_ledger_page.dart";
import "admin_pending_referrals_page.dart";
import "admin_users_page.dart";

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  late final AdminApiService _service;
  Future<AdminOverview>? _overviewFuture;

  @override
  void initState() {
    super.initState();
    _service = AdminApiService();
    _overviewFuture = _fetchOverview();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<AdminOverview> _fetchOverview() => _service.fetchOverview();

  Future<void> _refresh() async {
    final future = _fetchOverview();
    setState(() {
      _overviewFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin overview"),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AdminOverview>(
          future: _overviewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(
                message: "Failed to load dashboard data.",
                onRetry: _refresh,
              );
            }
            final overview = snapshot.data;
            if (overview == null) {
              return _ErrorView(
                message: "No overview data available.",
                onRetry: _refresh,
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildStatsSection(context, overview.stats),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  title: "Recent calls",
                  actionLabel: "View all",
                  onTap: () => _openPage(const AdminCallsPage()),
                ),
                const SizedBox(height: 12),
                _ActivityList(
                  emptyLabel: "No calls recorded yet.",
                  entries: overview.recentCalls
                      .map(
                        (call) => _ActivityEntry(
                          title: call.planName ?? "Plan",
                          subtitle: formatUserDisplay(call.user),
                          trailing: formatCurrency(call.amount),
                          timestamp: call.createdAt,
                          status: call.status,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  title: "Top-ups",
                  actionLabel: "Wallet ledger",
                  onTap: () => _openPage(
                    const AdminWalletLedgerPage(initialFilter: LedgerFilter.credit),
                  ),
                ),
                const SizedBox(height: 12),
                _ActivityList(
                  emptyLabel: "No wallet top-ups yet.",
                  entries: overview.recentTopUps
                      .map(
                        (entry) => _ActivityEntry(
                          title: entry.type ?? "Wallet credit",
                          subtitle: formatUserDisplay(entry.user),
                          trailing: formatCurrency(entry.amount),
                          timestamp: entry.createdAt,
                          status: entry.status,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  title: "Withdrawals",
                  actionLabel: "Wallet ledger",
                  onTap: () => _openPage(
                    const AdminWalletLedgerPage(initialFilter: LedgerFilter.debit),
                  ),
                ),
                const SizedBox(height: 12),
                _ActivityList(
                  emptyLabel: "No withdrawals recorded.",
                  entries: overview.recentWithdrawals
                      .map(
                        (entry) => _ActivityEntry(
                          title: entry.type ?? "Wallet debit",
                          subtitle: formatUserDisplay(entry.user),
                          trailing: formatCurrency(entry.amount),
                          timestamp: entry.createdAt,
                          status: entry.status,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  title: "Leaderboard",
                  actionLabel: "Users",
                  onTap: () => _openPage(const AdminUsersPage()),
                ),
                const SizedBox(height: 12),
                _buildLeaderboard(overview.leaderboardEntries),
                const SizedBox(height: 32),
                FilledButton.tonalIcon(
                  onPressed: () => _openPage(const AdminPendingReferralsPage()),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text("Review pending referrals"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, AdminOverviewStats stats) {
    final cards = [
      _MetricCardData(
        label: "Total signups",
        value: "${stats.totalSignups}",
        icon: Icons.person_outline,
        color: Colors.indigo,
      ),
      _MetricCardData(
        label: "Active users",
        value: "${stats.activeUsers}",
        icon: Icons.bolt_outlined,
        color: Colors.green.shade700,
      ),
      _MetricCardData(
        label: "Wallet balance",
        value: formatCurrency(stats.totalWalletBalance),
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.teal.shade700,
      ),
      _MetricCardData(
        label: "Pending referral",
        value: formatCurrency(stats.pendingReferralBalance),
        icon: Icons.group_add_outlined,
        color: Colors.orange.shade700,
      ),
      if (stats.totalRevenue != null)
        _MetricCardData(
          label: "Total revenue",
          value: formatCurrency(stats.totalRevenue),
          icon: Icons.trending_up_rounded,
          color: Colors.purple.shade700,
        ),
      if (stats.recentPayouts != null)
        _MetricCardData(
          label: "Recent payouts",
          value: formatCurrency(stats.recentPayouts),
          icon: Icons.payments_rounded,
          color: Colors.blueGrey.shade700,
        ),
    ];

    final columnCount = MediaQuery.of(context).size.width > 720 ? 2 : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: columnCount == 1 ? 2.8 : 2.4,
      ),
      itemBuilder: (context, index) {
        final data = cards[index];
        return _MetricCard(data: data);
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        if (actionLabel != null && onTap != null)
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel),
          ),
      ],
    );
  }

  Widget _buildLeaderboard(List<AdminLeaderboardEntry> entries) {
    if (entries.isEmpty) {
      return const _EmptyPanel(label: "Leaderboard data unavailable.");
    }
    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text("${entry.rank}"),
            ),
            title: Text(formatUserDisplay(entry.user)),
            subtitle: entry.metricLabel != null
                ? Text("${entry.metricLabel}")
                : null,
            trailing: Text(formatCurrency(entry.total)),
          );
        },
      ),
    );
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({
    required this.entries,
    required this.emptyLabel,
  });

  final List<_ActivityEntry> entries;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyPanel(label: emptyLabel);
    }
    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.history_rounded,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(entry.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subtitle),
                const SizedBox(height: 4),
                Text(
                  formatRelative(entry.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.trailing,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (entry.status != null)
                  Text(
                    entry.status!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.timestamp,
    this.status,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final DateTime? timestamp;
  final String? status;
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
            ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
