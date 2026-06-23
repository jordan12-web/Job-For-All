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
  String _currentStep = 'main';
  String? _responseTitle;
  String? _responseMessage;

  static const List<String> _jobCategories = <String>[
    'Construction',
    'Hospitality',
    'Retail',
    'Cleaning',
    'Driving',
    'Security',
    'Office Admin',
    'Skilled Trades',
  ];

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
      _currentStep = 'main';
      _responseTitle = null;
      _responseMessage = null;
      _selectionLog.add('Started USSD session with $shortCode');
    });
    _showMessage('USSD session started.');
  }

  void _handleMenuSelection(String selection) {
    final String code = selection.split('.').first.trim();

    setState(() {
      _selectionLog.add('Selected $selection');

      switch (code) {
        case '1':
          _currentStep = 'search';
          _responseTitle = 'Search jobs by category';
          _responseMessage =
              'Choose a job category and Job For All will send matching open roles to the phone number by SMS.';
          break;
        case '2':
          _currentStep = 'applyCategories';
          _responseTitle = 'Apply by category';
          _responseMessage =
              'Select the kind of work the applicant wants. The matching jobs in that category will be sent by SMS.';
          break;
        case '3':
          _currentStep = 'status';
          _responseTitle = 'Application status';
          _responseMessage =
              'A status summary is sent by SMS, including pending, shortlisted, and rejected applications.';
          break;
        case '4':
          _currentStep = 'employer';
          _responseTitle = 'Employer help';
          _responseMessage =
              'The employer receives an SMS link and callback instructions for posting jobs or upgrading a subscription.';
          break;
        case '5':
          _currentStep = 'support';
          _responseTitle = 'Support request';
          _responseMessage =
              'A support ticket is created and the user receives an SMS with the help desk contact and ticket number.';
          break;
        default:
          _currentStep = 'main';
          _responseTitle = 'USSD option received';
          _responseMessage = '$selection request confirmed.';
          break;
      }
    });
    _showMessage('USSD option confirmed.');
  }

  void _handleCategorySelection(String category) {
    setState(() {
      _currentStep = 'confirmation';
      _responseTitle = '$category jobs sent by SMS';
      _responseMessage =
          'The user receives an SMS with active $category jobs, employer names, locations, and the reply code to apply.';
      _selectionLog.add('Selected category: $category');
    });
    _showMessage('$category jobs queued for SMS.');
  }

  void _goBackToMainMenu() {
    setState(() {
      _currentStep = 'main';
      _responseTitle = null;
      _responseMessage = null;
      _selectionLog.add('Returned to main menu');
    });
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
              if (_menuVisible) ...<Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildUssdStep(),
                ),
              ],
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

  Widget _buildUssdStep() {
    switch (_currentStep) {
      case 'applyCategories':
      case 'search':
        return _CategoryStep(
          key: ValueKey<String>(_currentStep),
          title: _responseTitle ?? 'Choose a category',
          message: _responseMessage ?? '',
          categories: _jobCategories,
          onSelect: _handleCategorySelection,
          onBack: _goBackToMainMenu,
        );
      case 'status':
      case 'employer':
      case 'support':
      case 'confirmation':
        return _UssdResponseCard(
          key: ValueKey<String>(_currentStep),
          title: _responseTitle ?? 'Request confirmed',
          message: _responseMessage ?? '',
          onBack: _goBackToMainMenu,
        );
      case 'main':
      default:
        return UssdMenu(
          key: const ValueKey<String>('main'),
          onSelect: _handleMenuSelection,
        );
    }
  }
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({
    super.key,
    required this.title,
    required this.message,
    required this.categories,
    required this.onSelect,
    required this.onBack,
  });

  final String title;
  final String message;
  final List<String> categories;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _UssdStepHeader(title: title, message: message, onBack: onBack),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.map((String category) {
                return OutlinedButton.icon(
                  onPressed: () => onSelect(category),
                  icon: const Icon(Icons.work_outline),
                  label: Text(category),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _UssdResponseCard extends StatelessWidget {
  const _UssdResponseCard({
    super.key,
    required this.title,
    required this.message,
    required this.onBack,
  });

  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _UssdStepHeader(title: title, message: message, onBack: onBack),
      ),
    );
  }
}

class _UssdStepHeader extends StatelessWidget {
  const _UssdStepHeader({
    required this.title,
    required this.message,
    required this.onBack,
  });

  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(message),
      ],
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
