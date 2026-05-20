import 'package:flutter/material.dart';

import '../data/mock_application_store.dart';

class ApplicantsPage extends StatelessWidget {
  const ApplicantsPage({super.key, this.showAppBar = true});

  static const String routeName = '/applicants';

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Applicants',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (MockApplicationStore.applications.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No applications have been submitted yet.'),
                  ),
                )
              else
                ...MockApplicationStore.applications.reversed.map(
                  (Map<String, String> application) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ApplicantCard(application: application),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Applicants')),
      body: content,
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.application});

  final Map<String, String> application;

  @override
  Widget build(BuildContext context) {
    final String applicantName =
        application['applicantName'] ?? 'Unknown applicant';
    final String jobTitle = application['jobTitle'] ?? 'Unknown job';
    final String company = application['company'] ?? 'Unknown company';
    final String contact = application['contact'] ?? 'No contact provided';
    final String source = application['source'] ?? 'Unknown source';
    final String summary = application['summary'] ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.assignment_ind,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    applicantName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('$jobTitle at $company'),
            const SizedBox(height: 6),
            Text('Contact: $contact'),
            const SizedBox(height: 6),
            Text('Application source: $source'),
            const SizedBox(height: 12),
            Text(summary),
          ],
        ),
      ),
    );
  }
}
