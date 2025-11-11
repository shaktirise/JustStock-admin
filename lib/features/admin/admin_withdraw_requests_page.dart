import "package:flutter/material.dart";

import "data/admin_api_service.dart";
import "data/admin_models.dart";
import "util/admin_formatters.dart";
import "admin_user_detail_page.dart";
import "widgets/admin_scaffold.dart";

class AdminWithdrawRequestsPage extends StatelessWidget {
  const AdminWithdrawRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AdminScaffold(
        title: 'Withdraw requests',
        actions: const [
          TabBar(tabs: [
            Tab(text: 'Referral'),
            Tab(text: 'Wallet'),
          ]),
        ],
        body: const TabBarView(
          children: [
            _ReferralWithdrawalsTab(),
            _WalletWithdrawalsTab(),
          ],
        ),
      ),
    );
  }
}

class _MarkPaidParams {
  _MarkPaidParams({required this.paymentRef, this.note});
  final String paymentRef;
  final String? note;
}

class _ReferralWithdrawalsTab extends StatefulWidget {
  const _ReferralWithdrawalsTab();

  @override
  State<_ReferralWithdrawalsTab> createState() => _ReferralWithdrawalsTabState();
}

class _ReferralWithdrawalsTabState extends State<_ReferralWithdrawalsTab> {
  late final AdminApiService _service;
  final _userIdController = TextEditingController();
  String _status = 'pending';
  int _page = 1;
  int _limit = 20;
  bool _isLoading = false;
  String? _error;
  PaginatedResult<AdminWithdrawalRequest>? _result;

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
      final result = await _service.fetchReferralWithdrawals(
        page: _page,
        limit: _limit,
        status: _status,
        userId: _userIdController.text.trim().isEmpty
            ? null
            : _userIdController.text.trim(),
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
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

  Future<void> _markPaid(AdminWithdrawalRequest req) async {
    final paymentRefController = TextEditingController();
    final noteController = TextEditingController();
    bool settleFullPending = true; // default to zero referral wallet
    final values = await showDialog<_MarkPaidParams>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark referral paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: paymentRefController,
              decoration: const InputDecoration(
                labelText: 'Payment reference (UTR/txn-id)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Admin note (optional)',
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: settleFullPending,
                onChanged: (v) => setState(() => settleFullPending = v ?? true),
                title: const Text('Settle full pending (zero referral wallet)'),
                subtitle: const Text('Also mark any new pending commissions as paid.'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ref = paymentRefController.text.trim();
              if (ref.isEmpty) return;
              final note = noteController.text.trim();
              Navigator.of(context).pop(_MarkPaidParams(
                paymentRef: ref,
                note: note.isEmpty ? null : note,
              ));
            },
            child: const Text('Confirm paid'),
          ),
        ],
      ),
    );
    paymentRefController.dispose();
    noteController.dispose();
    if (!mounted || values == null) return;
    setState(() => _isLoading = true);
    try {
      await _service.markReferralWithdrawalPaid(
        requestId: req.id,
        paymentRef: values.paymentRef,
        adminNote: values.note,
        settleFullPending: settleFullPending,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral marked as paid.')),
      );
      await _load(resetPage: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final isEmpty = (!_isLoading && _error == null && (result?.items.isEmpty ?? true));
    return RefreshIndicator(
      onRefresh: () => _load(resetPage: true),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildFilters(),
          const SizedBox(height: 16),
          if (_error != null)
            _ErrorBanner(message: _error!, onRetry: () => _load(resetPage: false)),
          if (_isLoading) const LinearProgressIndicator(),
          if (isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: _EmptyState(message: 'No referral withdrawal requests.'),
            ),
          if (!isEmpty) ...[
            _buildList(result?.items ?? const []),
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
            Text('Filters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      labelText: 'User ID (optional)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onSubmitted: (_) => _load(resetPage: true),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _status,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                    _load(resetPage: true);
                  },
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _limit,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _limit = value);
                    _load(resetPage: true);
                  },
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 20, child: Text('20')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                  ],
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _load(resetPage: true),
                  icon: const Icon(Icons.search),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AdminWithdrawalRequest> items) {
    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final req = items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.payments_outlined),
            ),
            title: Text(formatUserDisplay(req.user)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatMethod(req)),
                if ((req.method).toUpperCase() == 'BANK') ...[
                  if ((req.bankAccountName ?? '').trim().isNotEmpty)
                    Text('Name: ${req.bankAccountName}')
                  else if ((req.contactName ?? '').trim().isNotEmpty)
                    Text('Name: ${req.contactName}'),
                  if ((req.bankAccountNumber ?? '').trim().isNotEmpty)
                    Text('Account: ${req.bankAccountNumber}')
                  else
                    const SizedBox.shrink(),
                ]
                else if ((req.method).toUpperCase() == 'UPI') ...[
                  if ((req.contactName ?? '').trim().isNotEmpty)
                    Text('Name: ${req.contactName}'),
                  if ((req.contactMobile ?? '').trim().isNotEmpty)
                    Text('Mobile: ${req.contactMobile}'),
                ],
                if ((req.note ?? '').trim().isNotEmpty)
                  Text((req.note ?? '').trim()),
                const SizedBox(height: 4),
                Text(
                  formatDateTime(req.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(req.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => _markPaid(req),
                  child: const Text('Mark paid'),
                ),
              ],
            ),
            onTap: () => _showWithdrawalDetails(req),
            onLongPress: req.user?.id == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AdminUserDetailPage(userId: req.user!.id),
                      ),
                    ),
          );
        },
      ),
    );
  }

  String _formatMethod(AdminWithdrawalRequest req) {
    final m = (req.method).toUpperCase();
    if (m == 'UPI') {
      return 'UPI: ${req.upiId ?? '-'}';
    }
    final acct = req.bankAccountNumber;
    final masked = acct != null && acct.length > 4
        ? '${acct.substring(0, acct.length - 4).replaceAll(RegExp(r'\d'), 'X')}${acct.substring(acct.length - 4)}'
        : (acct ?? '-');
    final ifsc = req.bankIfsc ?? '-';
    final bank = req.bankName ?? 'BANK';
    return 'BANK: $bank $masked IFSC $ifsc';
  }

  Future<void> _showWithdrawalDetails(AdminWithdrawalRequest req) async {
    final lines = <String>[
      'Method: ${req.method}',
      if ((req.upiId ?? '').trim().isNotEmpty) 'UPI: ${req.upiId}',
      if ((req.bankAccountName ?? '').trim().isNotEmpty) 'Account Name: ${req.bankAccountName}',
      if ((req.bankAccountNumber ?? '').trim().isNotEmpty) 'Account Number: ${req.bankAccountNumber}',
      if ((req.bankIfsc ?? '').trim().isNotEmpty) 'IFSC: ${req.bankIfsc}',
      if ((req.bankName ?? '').trim().isNotEmpty) 'Bank: ${req.bankName}',
      if ((req.contactName ?? '').trim().isNotEmpty) 'Contact Name: ${req.contactName}',
      if ((req.contactMobile ?? '').trim().isNotEmpty) 'Contact Mobile: ${req.contactMobile}',
      if ((req.note ?? '').trim().isNotEmpty) 'Note: ${req.note}',
    ];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdrawal details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in lines) Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(l),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _WalletWithdrawalsTab extends StatefulWidget {
  const _WalletWithdrawalsTab();

  @override
  State<_WalletWithdrawalsTab> createState() => _WalletWithdrawalsTabState();
}

class _WalletWithdrawalsTabState extends State<_WalletWithdrawalsTab> {
  late final AdminApiService _service;
  final _userIdController = TextEditingController();
  String _status = 'pending';
  int _page = 1;
  int _limit = 20;
  bool _isLoading = false;
  String? _error;
  PaginatedResult<AdminWithdrawalRequest>? _result;

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
      final result = await _service.fetchWalletWithdrawals(
        page: _page,
        limit: _limit,
        status: _status,
        userId: _userIdController.text.trim().isEmpty
            ? null
            : _userIdController.text.trim(),
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
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

  Future<void> _markPaid(AdminWithdrawalRequest req) async {
    final paymentRefController = TextEditingController();
    final ok = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark wallet withdrawal paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will debit the entire wallet balance and set it to zero.'),
            const SizedBox(height: 12),
            TextField(
              controller: paymentRefController,
              decoration: const InputDecoration(
                labelText: 'Payment reference (UTR/txn-id)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ref = paymentRefController.text.trim();
              if (ref.isEmpty) return;
              Navigator.of(context).pop(ref);
            },
            child: const Text('Confirm paid'),
          ),
        ],
      ),
    );
    paymentRefController.dispose();
    if (!mounted || ok == null) return;
    setState(() => _isLoading = true);
    try {
      await _service.markWalletWithdrawalPaid(
        id: req.id,
        paymentRef: ok,
        settleFullBalance: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet withdrawal marked as paid and wallet set to zero.')),
      );
      await _load(resetPage: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel(AdminWithdrawalRequest req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel withdrawal?'),
        content: const Text('Are you sure you want to cancel this withdrawal request?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await _service.cancelWalletWithdrawal(id: req.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal cancelled.')),
      );
      await _load(resetPage: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final isEmpty = (!_isLoading && _error == null && (result?.items.isEmpty ?? true));
    return RefreshIndicator(
      onRefresh: () => _load(resetPage: true),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildFilters(),
          const SizedBox(height: 16),
          if (_error != null)
            _ErrorBanner(message: _error!, onRetry: () => _load(resetPage: false)),
          if (_isLoading) const LinearProgressIndicator(),
          if (isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: _EmptyState(message: 'No wallet withdrawal requests.'),
            ),
          if (!isEmpty) ...[
            _buildList(result?.items ?? const []),
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
            Text('Filters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      labelText: 'User ID (optional)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onSubmitted: (_) => _load(resetPage: true),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _status,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                    _load(resetPage: true);
                  },
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _limit,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _limit = value);
                    _load(resetPage: true);
                  },
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 20, child: Text('20')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                  ],
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _load(resetPage: true),
                  icon: const Icon(Icons.search),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AdminWithdrawalRequest> items) {
    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final req = items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.payments_rounded),
            ),
            title: Text(formatUserDisplay(req.user)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatMethod(req)),
                if ((req.note ?? '').trim().isNotEmpty)
                  Text((req.note ?? '').trim()),
                const SizedBox(height: 4),
                Text(
                  formatDateTime(req.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
            trailing: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  formatCurrency(req.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                OutlinedButton(
                  onPressed: () => _cancel(req),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => _markPaid(req),
                  child: const Text('Mark paid'),
                ),
              ],
            ),
            onTap: req.user?.id == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AdminUserDetailPage(userId: req.user!.id),
                      ),
                    ),
          );
        },
      ),
    );
  }

  String _formatMethod(AdminWithdrawalRequest req) {
    final m = (req.method).toUpperCase();
    if (m == 'UPI') {
      return 'UPI: ${req.upiId ?? '-'}';
    }
    final acct = req.bankAccountNumber;
    final masked = acct != null && acct.length > 4
        ? '${acct.substring(0, acct.length - 4).replaceAll(RegExp(r'\d'), 'X')}${acct.substring(acct.length - 4)}'
        : (acct ?? '-');
    final ifsc = req.bankIfsc ?? '-';
    final bank = req.bankName ?? 'BANK';
    return 'BANK: $bank $masked IFSC $ifsc';
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
    final computed = (total <= 0 || limit <= 0) ? 1 : (total / limit).ceil();
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
                    color: Theme.of(context).colorScheme.onErrorContainer.withValues(alpha: 0.9),
                  ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
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
          Icons.archive_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}
