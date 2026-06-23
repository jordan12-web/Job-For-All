import 'package:flutter/material.dart';

import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/ussd_menu.dart';

class UssdSimulationPage extends StatefulWidget {
  const UssdSimulationPage({super.key, this.showAppBar = true});

  static const String routeName = '/ussd-simulation';

  final bool showAppBar;

  @override
  State<UssdSimulationPage> createState() => _UssdSimulationPageState();
}

class _UssdSimulationPageState extends State<UssdSimulationPage> {
  final TextEditingController _shortCodeController = TextEditingController();
  final FocusNode _shortCodeFocus = FocusNode();
  final List<String> _selectionLog = <String>[];

  bool _menuVisible = false;
  String? _shortCodeError;

  @override
  void dispose() {
    _shortCodeController.dispose();
    _shortCodeFocus.dispose();
    super.dispose();
  }

  void _startSession() {
    final String shortCode = _shortCodeController.text.trim();

    if (shortCode.isEmpty ||
        !shortCode.startsWith('*') ||
        !shortCode.endsWith('#')) {
      setState(() {
        _shortCodeError = 'Enter a valid short code, for example *123#.';
        _menuVisible = false;
      });
      return;
    }

    setState(() {
      _shortCodeError = null;
      _menuVisible = true;
      _selectionLog.add('Started USSD session with $shortCode');
    });
    _showMessage('USSD session started.');
  }

  void _handleMenuSelection(String selection) {
    setState(() {
      _selectionLog.add('Selected $selection');
    });
    _showMessage('$selection request confirmed.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'USSD Simulation',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      CommonTextField(
                        controller: _shortCodeController,
                        labelText: 'Short Code',
                        hasError: _shortCodeError != null,
                        focusNode: _shortCodeFocus,
                        onSubmitted: _startSession,
                      ),
                      if (_shortCodeError != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          _shortCodeError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      CommonButton(
                        label: 'Start USSD Session',
                        icon: Icons.dialpad,
                        onPressed: _startSession,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_menuVisible) UssdMenu(onSelect: _handleMenuSelection),
              const SizedBox(height: 24),
              _UssdLogCard(entries: _selectionLog),
            ],
          ),
        ),
      ),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('USSD Simulation')),
      body: content,
    );
  }
}

class _UssdLogCard extends StatelessWidget {
  const _UssdLogCard({required this.entries});

  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Selection Log',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('No USSD selections logged yet.')
            else
              ...entries.reversed.map(
                (String entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
