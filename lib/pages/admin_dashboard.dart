import 'package:flutter/material.dart';

import '../data/mock_job_store.dart';
import '../data/mock_profile_store.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, this.showAppBar = true});

  static const String routeName = '/admin-dashboard';

  final bool showAppBar;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    Color? confirmColor,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: confirmColor != null
                  ? FilledButton.styleFrom(backgroundColor: confirmColor)
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _approveJob(Map<String, String> job) async {
    final bool confirmed = await _confirmAction(
      title: 'Approve job post?',
      message:
          '“${job['title'] ?? 'This job'}” will become visible to job seekers.',
      confirmLabel: 'Approve',
    );
    if (!confirmed) {
      return;
    }

    setState(() => MockJobStore.updateJobStatus(job, 'Approved'));
    _showMessage('Job approved.');
  }

  Future<void> _rejectJob(Map<String, String> job) async {
    final bool confirmed = await _confirmAction(
      title: 'Reject job post?',
      message: 'Employers will need to revise “${job['title'] ?? 'this job'}”.',
      confirmLabel: 'Reject',
      confirmColor: Colors.orange.shade800,
    );
    if (!confirmed) {
      return;
    }

    setState(() => MockJobStore.updateJobStatus(job, 'Rejected'));
    _showMessage('Job rejected.');
  }

  Future<void> _deleteJob(Map<String, String> job) async {
    final bool confirmed = await _confirmAction(
      title: 'Delete job post?',
      message:
          'This permanently removes “${job['title'] ?? 'this job'}”. This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: Colors.redAccent,
    );
    if (!confirmed) {
      return;
    }

    setState(() => MockJobStore.deleteJob(job));
    _showMessage('Job deleted.');
  }

  Future<void> _verifyJobSeekerProfile() async {
    final bool confirmed = await _confirmAction(
      title: 'Verify job seeker?',
      message: 'Mark this profile as credential-verified for employers.',
      confirmLabel: 'Verify',
    );
    if (!confirmed) {
      return;
    }

    setState(MockProfileStore.markJobSeekerVerified);
    _showMessage('Job seeker profile marked as verified.');
  }

  Future<void> _flagJobSeekerAccount() async {
    final bool confirmed = await _confirmAction(
      title: 'Flag job seeker account?',
      message: 'The account will be marked for admin review.',
      confirmLabel: 'Flag account',
      confirmColor: Colors.orange.shade800,
    );
    if (!confirmed) {
      return;
    }

    setState(MockProfileStore.flagJobSeekerAccount);
    _showMessage('Job seeker account flagged.');
  }

  Future<void> _flagEmployerAccount() async {
    final bool confirmed = await _confirmAction(
      title: 'Flag employer account?',
      message: 'The employer profile will be marked for admin review.',
      confirmLabel: 'Flag account',
      confirmColor: Colors.orange.shade800,
    );
    if (!confirmed) {
      return;
    }

    setState(MockProfileStore.flagEmployerAccount);
    _showMessage('Employer account flagged.');
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading moderation tools…',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Admin Moderation',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Review listings, verify profiles, and keep the platform trustworthy.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 20),
                      _ModerationTable(
                        onApprove: _approveJob,
                        onReject: _rejectJob,
                        onDelete: _deleteJob,
                      ),
                      const SizedBox(height: 24),
                      _VerificationPanel(
                        onVerifyJobSeeker: _verifyJobSeekerProfile,
                        onFlagJobSeeker: _flagJobSeekerAccount,
                        onFlagEmployer: _flagEmployerAccount,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: content,
    );
  }
}

class _ModerationTable extends StatelessWidget {
  const _ModerationTable({
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  final Future<void> Function(Map<String, String> job) onApprove;
  final Future<void> Function(Map<String, String> job) onReject;
  final Future<void> Function(Map<String, String> job) onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Job Posts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                ),
                columns: const <DataColumn>[
                  DataColumn(label: Text('Job Title')),
                  DataColumn(label: Text('Employer')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: MockJobStore.jobs.map((Map<String, String> job) {
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text(job['title'] ?? 'Untitled Job')),
                      DataCell(Text(job['company'] ?? 'Unknown Employer')),
                      DataCell(_StatusPill(status: job['status'] ?? 'Pending')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              tooltip: 'Approve',
                              onPressed: () => onApprove(job),
                              icon: const Icon(Icons.check_circle_outline),
                              color: Colors.green.shade700,
                            ),
                            IconButton(
                              tooltip: 'Reject',
                              onPressed: () => onReject(job),
                              icon: const Icon(Icons.cancel_outlined),
                              color: Colors.orange.shade800,
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => onDelete(job),
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.redAccent,
                            ),
                          ],
                        ),
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

class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({
    required this.onVerifyJobSeeker,
    required this.onFlagJobSeeker,
    required this.onFlagEmployer,
  });

  final Future<void> Function() onVerifyJobSeeker;
  final Future<void> Function() onFlagJobSeeker;
  final Future<void> Function() onFlagEmployer;

  @override
  Widget build(BuildContext context) {
    final bool hasJobSeekerProfile =
        MockProfileStore.jobSeekerProfile.isNotEmpty;
    final bool hasEmployerProfile = MockProfileStore.employerProfile.isNotEmpty;
    final bool isVerified =
        MockProfileStore.jobSeekerProfile['Verified'] == 'true';
    final String document =
        MockProfileStore.jobSeekerProfile['Verification Document'] ??
        'No document uploaded';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Account Verification',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text('Job seeker document: $document'),
            const SizedBox(height: 8),
            Text(
              'Job seeker status: ${isVerified ? 'Verified' : 'Not verified'}',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: hasJobSeekerProfile ? onVerifyJobSeeker : null,
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Mark Profile Verified'),
                ),
                OutlinedButton.icon(
                  onPressed: hasJobSeekerProfile ? onFlagJobSeeker : null,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Flag Job Seeker'),
                ),
                OutlinedButton.icon(
                  onPressed: hasEmployerProfile ? onFlagEmployer : null,
                  icon: const Icon(Icons.business_outlined),
                  label: const Text('Flag Employer'),
                ),
              ],
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
    final Color color = switch (status) {
      'Approved' => Colors.green,
      'Rejected' => Colors.redAccent,
      _ => Colors.orange,
    };

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
