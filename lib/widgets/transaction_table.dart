import 'package:flutter/material.dart';

class TransactionTable extends StatelessWidget {
  const TransactionTable({super.key, required this.transactions});

  final List<Map<String, String>> transactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Transaction History',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (transactions.isEmpty)
              const Text('No transactions have been recorded yet.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                  ),
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Item')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: transactions.reversed.map((Map<String, String> item) {
                    return DataRow(
                      cells: <DataCell>[
                        DataCell(Text(item['date'] ?? 'Unknown')),
                        DataCell(Text(item['item'] ?? 'Unknown item')),
                        DataCell(Text(item['amount'] ?? '0')),
                        DataCell(
                          _StatusPill(status: item['status'] ?? 'Pending'),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final bool success = status == 'Confirmed';
    final Color color = success ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
