import "package:flutter/material.dart";

import "data/admin_api_service.dart";
import "data/admin_models.dart";
import "util/admin_formatters.dart";
import "admin_calls_page.dart";
import "admin_wallet_ledger_page.dart";
import "widgets/admin_scaffold.dart";

class AdminUserDetailPage extends StatefulWidget {
  const AdminUserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  late final AdminApiService _service;
  Future<AdminUserDetail>? _detailFuture;

  PaginatedResult<AdminWalletEntry>? _ledger;
  PaginatedResult<AdminReferralEntry>? _referrals;
  bool _loadingLedger = false;
  bool _loadingReferrals = false;
  LedgerFilter _ledgerFilter = LedgerFilter.all;
  String _referralStatus = "all";
  int _ledgerPage = 1;
  int _referralPage = 1;

  bool _isResettingPassword = false;

  @override
  void initState() {
    super.initState();
    _service = AdminApiService();
    _detailFuture = _loadDetail();
    _fetchLedger(resetPage: true);
    _fetchReferrals(resetPage: true);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<AdminUserDetail> _loadDetail() async {
    return _service.fetchUserProfile(widget.userId);
  }

  Future<void> _refresh() async {
    final future = _loadDetail();
    setState(() {
      _detailFuture = future;
    });
    await future;
    await Future.wait([
      _fetchLedger(resetPage: true),
      _fetchReferrals(resetPage: true),
    ]);
  }

  Future<void> _fetchLedger({required bool resetPage}) async {
    if (_loadingLedger) return;
    if (resetPage) _ledgerPage = 1;
    setState(() {
      _loadingLedger = true;
    });
    try {
      final result = await _service.fetchUserWalletLedger(
        widget.userId,
        page: _ledgerPage,
        limit: 10,
        // Filter by direction is handled client-side; server only supports types CSV
        types: null,
        from: DateTime.utc(1970, 1, 1),
      );
      if (!mounted) return;
      setState(() {
        _ledger = result;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to load ledger: $error")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingLedger = false;
        });
      }
    }
  }

  Future<void> _fetchReferrals({required bool resetPage}) async {
    if (_loadingReferrals) return;
    if (resetPage) _referralPage = 1;
    setState(() {
      _loadingReferrals = true;
    });
    try {
      final result = await _service.fetchUserReferrals(
        widget.userId,
        page: _referralPage,
        limit: 10,
        status: _referralStatus == "all" ? null : _referralStatus,
      );
      if (!mounted) return;
      setState(() {
        _referrals = result;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to load referral history: $error")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingReferrals = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_isResettingPassword) return;
    final controller = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reset password"),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "New password",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (newPassword == null || newPassword.isEmpty) return;

    setState(() {
      _isResettingPassword = true;
    });
    try {
      await _service.resetUserPassword(
        userId: widget.userId,
        newPassword: newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset successfully.")),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset failed: $error")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  void _openCalls() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminCallsPage(
          key: ValueKey("calls-${widget.userId}"),
          initialUserId: widget.userId,
        ),
      ),
    );
  }

  void _openWalletLedger() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminWalletLedgerPage(
          initialUserId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'User profile',
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AdminUserDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Failed to load user details.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text("Retry"),
                  ),
                ],
              );
            }
            final detail = snapshot.data;
            if (detail == null) {
              return const Center(child: Text("No detail available."));
            }
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildHeader(detail),
                const SizedBox(height: 20),
                _buildWallet(detail.wallet),
                const SizedBox(height: 20),
                _buildReferralStats(detail.referralStats),
                const SizedBox(height: 12),
                _buildReferralCounts(detail.referralCounts, detail.referralTreeTotal),
                const SizedBox(height: 12),
                _buildReferralTree(detail.referralTree),
                const SizedBox(height: 20),
                _buildActions(),
                const SizedBox(height: 24),
                _buildRecentCalls(detail.recentCalls),
                const SizedBox(height: 24),
                _buildLedgerSection(),
                const SizedBox(height: 24),
                _buildReferralSection(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AdminUserDetail detail) {
    final summary = detail.summary;
    final user = summary.reference;
    final theme = Theme.of(context);
    final displayName = user.name?.trim();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(
                (displayName?.isNotEmpty ?? false)
                    ? displayName![0].toUpperCase()
                    : "#",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName?.isNotEmpty == true
                        ? displayName!
                        : user.id,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (user.email != null && user.email!.isNotEmpty)
                        _InfoChip(
                          icon: Icons.email_outlined,
                          label: user.email!,
                        ),
                      if (user.phone != null && user.phone!.isNotEmpty)
                        _InfoChip(
                          icon: Icons.phone_outlined,
                          label: user.phone!,
                        ),
                      _InfoChip(
                        icon: Icons.badge_outlined,
                        label: summary.role ?? "user",
                      ),
                      _InfoChip(
                        icon: Icons.calendar_month_outlined,
                        label: "Joined ${formatDateTime(summary.createdAt)}",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWallet(AdminWalletSnapshot wallet) {
    final cards = [
      _StatCardData(
        color: Colors.teal.shade700,
        label: "Available",
        value: formatCurrency(wallet.available),
      ),
      _StatCardData(
        color: Colors.deepOrange.shade700,
        label: "Locked",
        value: formatCurrency(wallet.locked),
      ),
      _StatCardData(
        color: Colors.blueGrey.shade700,
        label: "Pending",
        value: formatCurrency(wallet.pending),
      ),
    ];
    return _StatGrid(cards: cards, title: "Wallet totals");
  }

  Widget _buildReferralStats(AdminReferralStats stats) {
    final cards = [
      _StatCardData(
        color: Colors.indigo.shade700,
        label: "Pending",
        value: formatCurrency(stats.pending),
      ),
      _StatCardData(
        color: Colors.green.shade700,
        label: "Paid",
        value: formatCurrency(stats.paid),
      ),
      _StatCardData(
        color: Colors.red.shade700,
        label: "Cancelled",
        value: formatCurrency(stats.cancelled),
      ),
      _StatCardData(
        color: Colors.purple.shade700,
        label: "Total",
        value: formatCurrency(stats.total),
      ),
    ];
    return _StatGrid(cards: cards, title: "Referral summary");
  }
  
  Widget _buildReferralCounts(Map<int, int> counts, int totalFromDetail) {
    if (counts.isEmpty && totalFromDetail <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final levels = counts.keys.toList()..sort();
    final total = totalFromDetail > 0
        ? totalFromDetail
        : counts.values.fold<int>(0, (a, b) => a + (b));
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Referral levels",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_2_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text("Total: $total"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (levels.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final level in levels)
                    Chip(
                      avatar: const Icon(Icons.people_outline, size: 18),
                      label: Text("L$level: ${counts[level]}"),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralTree(AdminReferralTree? tree) {
    final theme = Theme.of(context);
    final levels = tree?.levels ?? const [];
    final nonEmptyLevels = levels.where((l) => l.descendants.isNotEmpty).toList();
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Referral tree",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (tree == null || nonEmptyLevels.isEmpty)
              const _EmptyState(message: "No downline users yet.")
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nonEmptyLevels.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final level = nonEmptyLevels[index];
                  return Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                      initiallyExpanded: index == 0,
                      title: Text(
                        "Level ${level.level} (${level.descendants.length} users)",
                        style: theme.textTheme.titleSmall,
                      ),
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: level.descendants.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final d = level.descendants[i];
                            final u = d.user;
                            final display = formatUserDisplay(u);
                            final email = (u.email ?? '').trim();
                            final subtitle = email.isNotEmpty ? email : (u.username ?? u.phone ?? '');
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text(
                                  (u.name ?? u.username ?? u.email ?? u.phone ?? '#')
                                      .toString()
                                      .trim()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                ),
                              ),
                              title: Text(display),
                              subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: _isResettingPassword ? null : _changePassword,
          icon: const Icon(Icons.lock_reset_rounded),
          label: const Text("Reset password"),
        ),
        OutlinedButton.icon(
          onPressed: _openCalls,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text("View calls"),
        ),
        OutlinedButton.icon(
          onPressed: _openWalletLedger,
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text("Wallet ledger"),
        ),
      ],
    );
  }

  Widget _buildRecentCalls(List<AdminCallRecord> calls) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recent purchases",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (calls.isEmpty)
              const _EmptyState(
                message: "No purchases captured for this user.",
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: calls.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final call = calls[index];
                  return ListTile(
                    title: Text(call.planName ?? "Plan"),
                    subtitle: Text(formatDateTime(call.createdAt)),
                    trailing: Text(formatCurrency(call.amount)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerSection() {
    final ledger = _ledger;
    final entries = ledger?.items ?? const [];
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Wallet ledger",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                DropdownButton<LedgerFilter>(
                  value: _ledgerFilter,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _ledgerFilter = value;
                    });
                    _fetchLedger(resetPage: true);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: LedgerFilter.all,
                      child: Text("All"),
                    ),
                    DropdownMenuItem(
                      value: LedgerFilter.credit,
                      child: Text("Credits"),
                    ),
                    DropdownMenuItem(
                      value: LedgerFilter.debit,
                      child: Text("Debits"),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingLedger)
              const LinearProgressIndicator()
            else if (entries.isEmpty)
              const _EmptyState(message: "No ledger entries yet.")
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    title: Text(entry.type ?? "Entry"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.description != null &&
                            entry.description!.isNotEmpty)
                          Text(entry.description!),
                        const SizedBox(height: 4),
                        Text(
                          formatDateTime(entry.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      formatCurrency(entry.amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ledgerTypeColor(context, entry),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            _PaginationControls(
              page: _ledgerPage,
              total: ledger?.total ?? 0,
              limit: ledger?.limit ?? 10,
              totalPages: ledger?.totalPages,
              onPageChanged: (delta) {
                final result = ledger;
                if (result == null) return;
                final computed = (result.total <= 0 || result.limit <= 0)
                    ? 1
                    : (result.total / result.limit).ceil();
                final rawMax = result.totalPages ?? computed;
                final maxPage = rawMax <= 0 ? 1 : rawMax;
                final next = (_ledgerPage + delta).clamp(1, maxPage);
                if (next == _ledgerPage) return;
                setState(() {
                  _ledgerPage = next;
                });
                _fetchLedger(resetPage: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralSection() {
    final referrals = _referrals;
    final entries = referrals?.items ?? const [];
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Referral history",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _referralStatus,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _referralStatus = value;
                    });
                    _fetchReferrals(resetPage: true);
                  },
                  items: const [
                    DropdownMenuItem(value: "all", child: Text("All")),
                    DropdownMenuItem(value: "pending", child: Text("Pending")),
                    DropdownMenuItem(value: "paid", child: Text("Paid")),
                    DropdownMenuItem(
                        value: "cancelled", child: Text("Cancelled")),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingReferrals)
              const LinearProgressIndicator()
            else if (entries.isEmpty)
              const _EmptyState(message: "No referral entries yet.")
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    title: Text("From ${formatUserDisplay(entry.sourceUser)}"),
                    subtitle: Text(formatDateTime(entry.createdAt)),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formatCurrency(entry.amount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          entry.status,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: entry.status.toLowerCase() == "paid"
                                ? Colors.green.shade700
                                : (entry.status.toLowerCase() == "pending"
                                    ? theme.colorScheme.primary
                                    : Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            _PaginationControls(
              page: _referralPage,
              total: referrals?.total ?? 0,
              limit: referrals?.limit ?? 10,
              totalPages: referrals?.totalPages,
              onPageChanged: (delta) {
                final result = referrals;
                if (result == null) return;
                final computed = (result.total <= 0 || result.limit <= 0)
                    ? 1
                    : (result.total / result.limit).ceil();
                final rawMax = result.totalPages ?? computed;
                final maxPage = rawMax <= 0 ? 1 : rawMax;
                final next = (_referralPage + delta).clamp(1, maxPage);
                if (next == _referralPage) return;
                setState(() {
                  _referralPage = next;
                });
                _fetchReferrals(resetPage: false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.cards, required this.title});

  final List<_StatCardData> cards;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = MediaQuery.of(context).size.width > 720 ? 2 : 1;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.2 : 2.6,
              ),
              itemBuilder: (context, index) {
                final data = cards[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: data.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.value,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
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

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.page,
    required this.total,
    required this.limit,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int page;
  final int total;
  final int limit;
  final int? totalPages;
  final void Function(int delta) onPageChanged;

  @override
  Widget build(BuildContext context) {
    final computed =
        (total <= 0 || limit <= 0) ? 1 : (total / limit).ceil();
    final rawMax = totalPages ?? computed;
    final maxPage = rawMax <= 0 ? 1 : rawMax;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Page $page of $maxPage"),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton(
              onPressed: page > 1 ? () => onPageChanged(-1) : null,
              child: const Text("Previous"),
            ),
            FilledButton(
              onPressed: page < maxPage ? () => onPageChanged(1) : null,
              child: const Text("Next"),
            ),
          ],
        ),
      ],
    );
  }
}
