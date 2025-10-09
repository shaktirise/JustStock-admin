import "dart:async";

import "package:flutter/material.dart";

import "data/admin_api_service.dart";
import "data/admin_models.dart";
import "util/admin_formatters.dart";
import "admin_user_detail_page.dart";

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late final AdminApiService _service;
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _role = "all";
  int _page = 1;
  int _limit = 20;

  PaginatedResult<AdminUserSummary>? _result;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AdminApiService();
    _load(resetPage: true);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _service.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _load(resetPage: true);
    });
  }

  Future<void> _load({required bool resetPage}) async {
    if (_isLoading) return;
    if (resetPage) _page = 1;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.fetchUsers(
        page: _page,
        limit: _limit,
        role: _role == "all" ? null : _role,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final isEmpty =
        (!_isLoading && _error == null && (result?.items.isEmpty ?? true));
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users"),
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
                child: _EmptyState(message: "No users matched your query."),
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
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Search name, email, phone",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _role,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _role = value;
                    });
                    _load(resetPage: true);
                  },
                  items: const [
                    DropdownMenuItem(value: "all", child: Text("All roles")),
                    DropdownMenuItem(value: "user", child: Text("Users")),
                    DropdownMenuItem(value: "admin", child: Text("Admins")),
                  ],
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AdminUserSummary> users) {
    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(
                user.reference.name != null && user.reference.name!.isNotEmpty
                    ? user.reference.name![0].toUpperCase()
                    : "#",
              ),
            ),
            title: Text(formatUserDisplay(user.reference)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.role != null)
                  Text(
                    "Role: ${user.role}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 4),
                Text(
                  "Wallet ${formatCurrency(user.walletBalance)} · Pending ${formatCurrency(user.pendingReferral)}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  "Joined ${formatDateTime(user.createdAt)}",
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
                  "${user.totalCalls ?? 0} calls",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (user.totalReferralPaid != null)
                  Text(
                    "Paid ${formatCurrency(user.totalReferralPaid)}",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
            onTap: () => _openUserDetail(user.reference.id),
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
          Icons.group_outlined,
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
