import "package:flutter/material.dart";

import "data/admin_api_service.dart";
import "data/admin_models.dart";
import "util/admin_formatters.dart";
import "admin_user_detail_page.dart";
import "widgets/admin_scaffold.dart";

class AdminCallsPage extends StatefulWidget {
  const AdminCallsPage({
    super.key,
    this.initialUserId,
    this.initialRange,
  });

  final String? initialUserId;
  final DateTimeRange? initialRange;

  @override
  State<AdminCallsPage> createState() => _AdminCallsPageState();
}

class _AdminCallsPageState extends State<AdminCallsPage> {
  late final AdminApiService _service;
  final _userIdController = TextEditingController();

  PaginatedResult<AdminCallRecord>? _result;
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  int _limit = 20;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _service = AdminApiService();
    if (widget.initialUserId != null && widget.initialUserId!.isNotEmpty) {
      _userIdController.text = widget.initialUserId!;
    }
    _dateRange = widget.initialRange;
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
    if (resetPage) {
      _page = 1;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.fetchCalls(
        page: _page,
        limit: _limit,
        userId: _userIdController.text.trim().isEmpty
            ? null
            : _userIdController.text.trim(),
        start: _dateRange?.start ?? DateTime.utc(1970, 1, 1),
        end: _dateRange?.end,
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (!mounted) return;
    if (range != null) {
      setState(() {
        _dateRange = range;
      });
      await _load(resetPage: true);
    }
  }

  void _clearDateRange() {
    if (_dateRange == null) return;
    setState(() {
      _dateRange = null;
    });
    _load(resetPage: true);
  }

  void _changePage(int delta) {
    final result = _result;
    if (result == null) return;
    final maxPage = result.totalPages ?? (result.total / result.limit).ceil();
    final newPage = (_page + delta).clamp(1, maxPage == 0 ? 1 : maxPage);
    if (newPage == _page) return;
    setState(() {
      _page = newPage;
    });
    _load(resetPage: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    final isEmpty = (!_isLoading && _error == null && (result?.items.isEmpty ?? true));

    return AdminScaffold(
      title: 'Purchase calls',
      body: RefreshIndicator(
        onRefresh: () => _load(resetPage: true),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _buildFilters(theme),
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
                child: _EmptyState(message: "No calls found for the selected filters."),
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

  Widget _buildFilters(ThemeData theme) {
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
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                InputChip(
                  label: Text(
                    _dateRange == null
                        ? "Any date range"
                        : _dateRangeLabel(_dateRange!),
                  ),
                  avatar: const Icon(Icons.date_range_outlined),
                  onPressed: _pickDateRange,
                  onDeleted: _dateRange == null ? null : _clearDateRange,
                  deleteIcon: const Icon(Icons.clear),
                ),
                ElevatedButton.icon(
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

  Widget _buildList(List<AdminCallRecord> calls) {
    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: calls.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final call = calls[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.call_made_outlined),
            ),
            title: Text(call.planName ?? "Plan"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatUserDisplay(call.user)),
                const SizedBox(height: 4),
                Text(
                  formatDateTime(call.createdAt),
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
                  formatCurrency(call.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (call.status != null)
                  Text(
                    call.status!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
              ],
            ),
            onTap: call.user?.id == null
                ? null
                : () => _openUserDetail(call.user!.id),
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

  String _dateRangeLabel(DateTimeRange range) {
    final start =
        "${range.start.day}/${range.start.month}/${range.start.year}";
    final end = "${range.end.day}/${range.end.month}/${range.end.year}";
    return "$start to $end";
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
          Icons.inbox_outlined,
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
