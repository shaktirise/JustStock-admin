import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "data/admin_api_service.dart";
import "data/admin_models.dart";
import "util/admin_formatters.dart";
import "widgets/admin_scaffold.dart";

class AdminWithdrawalDetailPage extends StatefulWidget {
  const AdminWithdrawalDetailPage({
    super.key,
    required this.request,
    this.isReferral = true,
  });

  final AdminWithdrawalRequest request;
  final bool isReferral; // true -> referral, false -> wallet

  @override
  State<AdminWithdrawalDetailPage> createState() => _AdminWithdrawalDetailPageState();
}

class _AdminWithdrawalDetailPageState extends State<AdminWithdrawalDetailPage> {
  late final AdminApiService _service;
  late AdminWithdrawalRequest _req;
  bool _isLoading = false;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _service = AdminApiService();
    _req = widget.request;
    _isPaid = (_req.status.toLowerCase() == 'paid');
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _copy(String label, String? value) async {
    final text = (value ?? '').trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  Future<void> _markPaid() async {
    if (_isPaid || _isLoading) return;
    setState(() => _isLoading = true);

    if (widget.isReferral) {
      // Ask for payment reference + optional note + settle mode
      final paymentRefController = TextEditingController();
      final noteController = TextEditingController();
      bool settleFullPending = true;
      final params = await showDialog<({String ref, String? note, bool settle})>(
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
                builder: (context, setSt) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settleFullPending,
                  onChanged: (v) => setSt(() => settleFullPending = v ?? true),
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
                Navigator.of(context).pop((ref: ref, note: note.isEmpty ? null : note, settle: settleFullPending));
              },
              child: const Text('Confirm paid'),
            ),
          ],
        ),
      );
      paymentRefController.dispose();
      noteController.dispose();
      if (!mounted || params == null) {
        setState(() => _isLoading = false);
        return;
      }
      try {
        await _service.markReferralWithdrawalPaid(
          requestId: _req.id,
          paymentRef: params.ref,
          adminNote: params.note,
          settleFullPending: params.settle,
        );
        if (!mounted) return;
        setState(() {
          _isPaid = true;
          _isLoading = false;
          _req = AdminWithdrawalRequest(
            id: _req.id,
            amount: _req.amount,
            status: 'paid',
            method: _req.method,
            user: _req.user,
            upiId: _req.upiId,
            bankAccountName: _req.bankAccountName,
            bankAccountNumber: _req.bankAccountNumber,
            bankIfsc: _req.bankIfsc,
            bankName: _req.bankName,
            contactName: _req.contactName,
            contactMobile: _req.contactMobile,
            note: _req.note,
            createdAt: _req.createdAt,
            updatedAt: DateTime.now(),
            metadata: _req.metadata,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral marked as paid.')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } else {
      // Wallet withdrawal flow: request only payment ref
      final paymentRefController = TextEditingController();
      final ref = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark wallet withdrawal paid'),
          content: TextField(
            controller: paymentRefController,
            decoration: const InputDecoration(
              labelText: 'Payment reference (UTR/txn-id)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final r = paymentRefController.text.trim();
                if (r.isEmpty) return;
                Navigator.of(context).pop(r);
              },
              child: const Text('Confirm paid'),
            ),
          ],
        ),
      );
      paymentRefController.dispose();
      if (!mounted || ref == null) {
        setState(() => _isLoading = false);
        return;
      }
      try {
        await _service.markWalletWithdrawalPaid(
          id: _req.id,
          paymentRef: ref,
          settleFullBalance: true,
        );
        if (!mounted) return;
        setState(() {
          _isPaid = true;
          _isLoading = false;
          _req = AdminWithdrawalRequest(
            id: _req.id,
            amount: _req.amount,
            status: 'paid',
            method: _req.method,
            user: _req.user,
            upiId: _req.upiId,
            bankAccountName: _req.bankAccountName,
            bankAccountNumber: _req.bankAccountNumber,
            bankIfsc: _req.bankIfsc,
            bankName: _req.bankName,
            contactName: _req.contactName,
            contactMobile: _req.contactMobile,
            note: _req.note,
            createdAt: _req.createdAt,
            updatedAt: DateTime.now(),
            metadata: _req.metadata,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet withdrawal marked as paid.')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpi = (_req.method).toUpperCase() == 'UPI';
    final title = widget.isReferral ? 'Referral withdrawal' : 'Wallet withdrawal';
    final bottom = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isPaid || _isLoading ? null : _markPaid,
            icon: Icon(_isPaid ? Icons.verified_outlined : Icons.check_circle_outline),
            label: Text(_isPaid ? 'Paid' : 'Mark paid'),
          ),
        ),
      ),
    );

    final body = WillPopScope(
      onWillPop: () async {
        if (_isPaid) {
          Navigator.of(context).pop(true);
          return false;
        }
        return true;
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _Section(
            title: 'User',
            children: [
              _kv('Name', _req.user?.name ?? _req.contactName ?? '-'),
              _kv('Mobile', _req.user?.phone ?? _req.contactMobile ?? '-'),
              _kv('User ID', _req.user?.id ?? '-', copyable: _req.user?.id),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Payment',
            children: [
              _kv('Method', _req.method),
              if (isUpi) ...[
                _kv('UPI ID', _req.upiId ?? '-', copyable: _req.upiId),
                _kv('Contact Name', _req.contactName ?? '-'),
                _kv('Contact Mobile', _req.contactMobile ?? '-'),
              ] else ...[
                _kv('Account Name', _req.bankAccountName ?? _req.contactName ?? '-'),
                _kv('Account Number', _req.bankAccountNumber ?? '-', copyable: _req.bankAccountNumber),
                _kv('IFSC', _req.bankIfsc ?? '-', copyable: _req.bankIfsc),
                _kv('Bank', _req.bankName ?? '-'),
                _kv('Contact Mobile', _req.contactMobile ?? '-'),
              ],
              _kv('Amount', formatFullCurrency(_req.amount)),
              if ((_req.note ?? '').trim().isNotEmpty) _kv('Note', _req.note!.trim()),
              _kv('Requested At', formatDateTime(_req.createdAt)),
            ],
          ),
        ],
      ),
    );

    return AdminScaffold(
      title: title,
      body: body,
      bottomBar: bottom,
    );
  }

  Widget _kv(String label, String value, {String? copyable}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if ((copyable ?? '').trim().isNotEmpty)
            IconButton(
              tooltip: 'Copy',
              onPressed: () => _copy(label, copyable),
              icon: const Icon(Icons.copy_all_outlined),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

