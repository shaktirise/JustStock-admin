import "package:flutter/material.dart";

import "data/admin_api_service.dart";
import "data/admin_models.dart";
import "util/admin_formatters.dart";
import "admin_user_detail_page.dart";

class AdminPendingReferralsPage extends StatefulWidget {
  const AdminPendingReferralsPage({super.key});

  @override
  State<AdminPendingReferralsPage> createState() =>
      _AdminPendingReferralsPageState();
}

class _AdminPendingReferralsPageState
    extends State<AdminPendingReferralsPage> {
  late final AdminApiService _service;
  final _userIdController = TextEditingController();

  PaginatedResult<AdminReferralEntry>? _result;
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  int _limit = 20;

  @override
  void initState() {
    super.initState();
    _service = AdminApiService();
    _load(resetPage: true);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _load({required bool resetPage}) async {
    if (_isLoading) return;
    if (resetPage) _page = 1;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.fetchPendingReferrals(
        page: _page,
        limit: _limit,
        userId: _userIdController.text.trim().isEmpty
            ? null
            : _userIdController.text.trim(),
      );
      setState(() {
        _result = result;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changePage(int delta) {
    final result = _result;
    if (result == null) return;
    final computed =
        (result.total <= 0 || result.limit <= 0) ? 1 : (result.total / result.limit).ceil();
    final rawMax = result.totalPages ?? computed;
    final maxPage = rawMax <= 0 ? 1 : rawMax;
    final newPage = (_page + delta).clamp(1, maxPage);
    if (newPage == _page) return;
    setState(() {
      _page = newPage;
    });
    _load(resetPage: false);
  }

  Future<void> _updateStatus({
    required AdminReferralEntry entry,
    required String status,
  }) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _service.updateReferralStatus(entryId: entry.id, status: status);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text("Marked referral as $status.")),
      );
      await _load(resetPage: true);
    } catch (error) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text("Failed to update status: $error")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final isEmpty =
        (!_isLoading && _error == null && (result?.items.isEmpty ?? true));
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending referrals"),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(resetPage: true),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            if (_error != null)
              _ErrorBanner(
                message: _error!,
                onRetry: () => _load(resetPage: false),
              ),
            if (_isLoading) const LinearProgressIndicator(),
            if (isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: _EmptyState(
                  message: "No pending referral entries found.",
                ),
              ),
            if (!isEmpty)
              ...[
                _buildList(result?.items ?? []),
                const SizedBox(height: 16),
                _PaginationControls(
                  page: _page,
                  total: result?.total ?? 0,
                  limit: _limit,
                  totalPages: result?.totalPages,
                  onPageChanged: _changePage,
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Filters",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      labelText: "User ID (optional)",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onSubmitted: (_) => _load(resetPage: true),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _limit,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _limit = value;
                    });
                    _load(resetPage: true);
                  },
                  items: const [
                    DropdownMenuItem(value: 10, child: Text("10")),
                    DropdownMenuItem(value: 20, child: Text("20")),
                    DropdownMenuItem(value: 50, child: Text("50")),
                  ],
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _load(resetPage: true),
                  icon: const Icon(Icons.search),
                  label: const Text("Apply"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AdminReferralEntry> entries) {
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
              backgroundColor:
                  Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.card_giftcard_outlined),
            ),
            title: Text(formatUserDisplay(entry.user)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.description != null &&
                    entry.description!.trim().isNotEmpty)
                  Text(entry.description!.trim()),
                const SizedBox(height: 4),
                Text(
                  "Source: ${formatUserDisplay(entry.sourceUser)}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  formatDateTime(entry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(entry.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _updateStatus(
                        entry: entry,
                        status: "cancelled",
                      ),
                      child: const Text("Cancel"),
                    ),
                    FilledButton(
                      onPressed: () => _updateStatus(
                        entry: entry,
                        status: "paid",
                      ),
                      child: const Text("Mark paid"),
                    ),
                  ],
                ),
              ],
            ),
            onTap: entry.user?.id == null
                ? null
                : () => _openUserDetail(entry.user!.id),
          );
        },
      ),
    );
  }

  void _openUserDetail(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminUserDetailPage(userId: userId),
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.page,
    required this.total,
    required this.limit,
    required this.onPageChanged,
    required this.totalPages,
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
        Text("Page $page of $maxPage | $total results"),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onErrorContainer
                        .withValues(alpha: 0.9),
                  ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.people_outline,
          size: 48,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.4),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}
