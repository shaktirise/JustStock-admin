import 'dart:async';

import 'package:flutter/material.dart';

import 'data/admin_api_service.dart';
import 'data/admin_models.dart';
import 'util/admin_formatters.dart';
import 'admin_user_detail_page.dart';
import 'widgets/admin_scaffold.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late final AdminApiService _service;
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _role = 'all';
  int _page = 1;
  int _limit = 20;

  PaginatedResult<AdminUserSummary>? _result;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AdminApiService();
    _searchController.addListener(() => setState(() {}));
    _load(resetPage: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _scheduleSearch(String _) {
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
        role: _role == 'all' ? null : _role,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    setState(() => _page = newPage);
    _load(resetPage: false);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final isEmpty = (!_isLoading && _error == null && (result?.items.isEmpty ?? true));
    return AdminScaffold(
      title: 'Users',
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
                child: _EmptyState(message: 'No users matched your query.'),
              ),
            if (!isEmpty) ...[
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: result!.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = result.items[index];
                    return _UserTile(
                      data: item,
                      onTap: () => _openDetail(item.reference.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _PaginationControls(
                page: _page,
                total: result.total,
                limit: result.limit,
                totalPages: result.totalPages,
                onPageChanged: _changePage,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSearchBar(
              controller: _searchController,
              hint: 'Search name, email, phone, ID',
              onChanged: _scheduleSearch,
              onClear: () => _load(resetPage: true),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRoleChip('all', label: 'All'),
                _buildRoleChip('user', label: 'Users'),
                _buildRoleChip('admin', label: 'Admins'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _limit,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(12),
                  items: const [10, 20, 50, 100]
                      .map((v) => DropdownMenuItem<int>(value: v, child: Text('Per page: $v')))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _limit = v);
                    _load(resetPage: true);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String value, {required String label}) {
    final selected = _role == value;
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) {
        if (_role == value) return;
        setState(() => _role = value);
        _load(resetPage: true);
      },
    );
  }

  void _openDetail(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminUserDetailPage(userId: userId),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.data, this.onTap});

  final AdminUserSummary data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ref = data.reference;
    final title = (ref.name != null && ref.name!.trim().isNotEmpty) ? ref.name!.trim() : ref.id;
    final initials = (ref.name ?? ref.id).isNotEmpty ? (ref.name ?? ref.id)[0].toUpperCase() : '#';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
        foregroundColor: Theme.of(context).colorScheme.primary,
        child: Text(initials),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((ref.email ?? '').isNotEmpty || (ref.phone ?? '').isNotEmpty)
            Text([
              if ((ref.email ?? '').isNotEmpty) ref.email!,
              if ((ref.phone ?? '').isNotEmpty) ref.phone!,
            ].join(' · ')),
          const SizedBox(height: 4),
          Text(
            'Joined: ${formatDateTime(data.createdAt)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatCurrency(data.walletBalance),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: Colors.green.shade700),
          ),
          if (data.pendingReferral != null)
            Text(
              'Pending: ${formatCurrency(data.pendingReferral)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
        ],
      ),
      onTap: onTap,
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
    final computed = (total <= 0 || limit <= 0) ? 1 : (total / limit).ceil();
    final rawMax = totalPages ?? computed;
    final maxPage = rawMax <= 0 ? 1 : rawMax;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Page $page of $maxPage | $total results'),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton(
              onPressed: page > 1 ? () => onPageChanged(-1) : null,
              child: const Text('Previous'),
            ),
            FilledButton(
              onPressed: page < maxPage ? () => onPageChanged(1) : null,
              child: const Text('Next'),
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
            child: const Text('Retry'),
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
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
