import 'package:flutter/material.dart';

import '../data/mock_payment_store.dart';
import '../widgets/common_button.dart';
import '../widgets/transaction_table.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, this.showAppBar = true});

  static const String routeName = '/payments';

  final bool showAppBar;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const List<Map<String, String>> _paymentItems = <Map<String, String>>[
    <String, String>{
      'title': 'Featured Job Post',
      'description': 'Boost one listing at the top of job search results.',
      'amount': 'KES 1,500',
    },
    <String, String>{
      'title': 'Employer Subscription',
      'description': 'Access monthly featured listings and applicant insights.',
      'amount': 'KES 5,000',
    },
  ];

  void _simulatePurchase(Map<String, String> item) {
    MockPaymentStore.addTransaction(
      item: item['title'] ?? 'Unknown item',
      amount: item['amount'] ?? 'KES 0',
      status: 'Confirmed',
    );

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment confirmed for ${item['title']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Payments',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool isWide = constraints.maxWidth >= 760;
                  final List<Widget> cards = _paymentItems.map((
                    Map<String, String> item,
                  ) {
                    return _PaymentOptionCard(
                      item: item,
                      onPurchase: () => _simulatePurchase(item),
                    );
                  }).toList();

                  if (!isWide) {
                    return Column(
                      children: cards
                          .map(
                            (Widget card) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: card,
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (
                        int index = 0;
                        index < cards.length;
                        index++
                      ) ...<Widget>[
                        Expanded(child: cards[index]),
                        if (index < cards.length - 1) const SizedBox(width: 16),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              TransactionTable(transactions: MockPaymentStore.transactions),
            ],
          ),
        ),
      ),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: content,
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({required this.item, required this.onPurchase});

  final Map<String, String> item;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.payments_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              item['title'] ?? 'Payment item',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(item['description'] ?? ''),
            const SizedBox(height: 16),
            Text(
              item['amount'] ?? 'KES 0',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            CommonButton(
              label: 'Simulate Payment',
              icon: Icons.lock,
              onPressed: onPurchase,
            ),
          ],
        ),
      ),
    );
  }
}
