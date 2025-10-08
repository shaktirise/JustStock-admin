import "package:flutter/material.dart";

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  static final List<_Transaction> _transactions = [
    _Transaction(id: "#TXN-14521", amount: "₹3,200", status: "Completed", timestamp: "Today • 10:32 AM"),
    _Transaction(id: "#TXN-14520", amount: "₹1,250", status: "Pending", timestamp: "Today • 09:18 AM"),
    _Transaction(id: "#TXN-14519", amount: "₹980", status: "Completed", timestamp: "Yesterday • 07:44 PM"),
    _Transaction(id: "#TXN-14518", amount: "₹1,540", status: "Refunded", timestamp: "Yesterday • 05:10 PM"),
    _Transaction(id: "#TXN-14517", amount: "₹3,100", status: "Completed", timestamp: "03 Oct • 03:58 PM"),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          transaction.status,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        transaction.amount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    transaction.id,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    transaction.timestamp,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Transaction {
  const _Transaction({
    required this.id,
    required this.amount,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final String amount;
  final String status;
  final String timestamp;
}
