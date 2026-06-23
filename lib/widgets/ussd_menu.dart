import 'package:flutter/material.dart';

class UssdMenu extends StatelessWidget {
  const UssdMenu({super.key, required this.onSelect});

  final ValueChanged<String> onSelect;

  static const List<_UssdOption> _options = <_UssdOption>[
    _UssdOption(code: '1', title: 'Search Jobs', icon: Icons.search),
    _UssdOption(code: '2', title: 'Apply', icon: Icons.send),
    _UssdOption(code: '3', title: 'Check Status', icon: Icons.fact_check),
    _UssdOption(code: '4', title: 'Employer Help', icon: Icons.business),
    _UssdOption(code: '5', title: 'Support', icon: Icons.support_agent),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'USSD Menu',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text('Choose an option to simulate a USSD response.'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _options.map((_UssdOption option) {
                return OutlinedButton.icon(
                  onPressed: () => onSelect('${option.code}. ${option.title}'),
                  icon: Icon(option.icon),
                  label: Text('${option.code}. ${option.title}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _UssdOption {
  const _UssdOption({
    required this.code,
    required this.title,
    required this.icon,
  });

  final String code;
  final String title;
  final IconData icon;
}
