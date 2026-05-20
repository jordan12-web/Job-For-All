import 'package:flutter/material.dart';

class JobDetailPage extends StatelessWidget {
  const JobDetailPage({super.key, required this.job});

  final Map<String, String> job;

  @override
  Widget build(BuildContext context) {
    final String title = job['title'] ?? 'Untitled Job';
    final String company = job['company'] ?? 'Unknown Company';
    final String location = job['location'] ?? 'Unknown Location';
    final String type = job['type'] ?? 'Unspecified';
    final String description = job['description'] ?? '';
    final String requirements = job['requirements'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$company - $location - $type',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    _DetailSection(title: 'Description', body: description),
                    const SizedBox(height: 20),
                    _DetailSection(title: 'Requirements', body: requirements),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(body.isEmpty ? 'Not provided.' : body),
      ],
    );
  }
}
