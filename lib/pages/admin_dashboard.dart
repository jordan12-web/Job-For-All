import 'package:flutter/material.dart';

import '../data/mock_profile_store.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../utils/debug_logger.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, this.showAppBar = true});

  static const String routeName = '/admin-dashboard';

  final bool showAppBar;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Job> _pendingJobs = <Job>[];
  bool _isLoading = true;
  String? _loadError;

  // Tracks which job IDs are currently being updated so we can show
  // a per-row spinner without blocking the rest of the table.
  final Set<String> _updatingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      DebugLogger.step('AdminDashboard: loading pending jobs');
      final List<Job> jobs = await JobService.instance.fetchPendingJobs();

      if (!mounted) {
        return;
      }

      DebugLogger.success('AdminDashboard: ${jobs.length} pending jobs');
      setState(() {
        _pendingJobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      DebugLogger.error('AdminDashboard load failed: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load pending jobs. Pull down to retry.';
      });
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

  Future<void> _updateJobStatus(Job job, String newStatus) async {
    if (_updatingIds.contains(job.id)) {
      return;
    }

    final String actionLabel =
        newStatus == 'Approved' ? 'Approve' : 'Reject';
    final String actionMessage = newStatus == 'Approved'
        ? '"${job.title}" will become visible to job seekers.'
        : 'Employers will need to revise "${job.title}".';

    final bool confirmed = await _confirmAction(
      title: '$actionLabel job post?',
      message: actionMessage,
      confirmLabel: actionLabel,
      confirmColor:
          newStatus == 'Rejected' ? Colors.orange.shade800 : null,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _updatingIds.add(job.id));

    DebugLogger.step(
      'AdminDashboard: updating ${job.id} → $newStatus',
    );

    final bool success = await JobService.instance.updateJobStatus(
      jobId: job.id,
      status: newStatus,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _updatingIds.remove(job.id);
      if (success) {
        // Remove from pending list — it's no longer pending
        _pendingJobs.removeWhere((Job j) => j.id == job.id);
      }
    });

    if (success) {
      _showMessage('Job $actionLabel.toLowerCase()d successfully.');
    } else {
      _showMessage('Failed to update job status.', isError: true);
    }
  }

  // ── Mock profile actions — unchanged from original ─────────────────────────

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
    final Widget content = RefreshIndicator(
      onRefresh: _loadDashboard,
      child: _buildBody(context),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: content,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
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
      );
    }

    if (_loadError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: <Widget>[
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
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
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Review listings, verify profiles, and keep the platform trustworthy.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              // ── Job moderation table ──────────────────────────
              _JobModerationTable(
                pendingJobs: _pendingJobs,
                updatingIds: _updatingIds,
                onApprove: (Job job) => _updateJobStatus(job, 'Approved'),
                onReject: (Job job) => _updateJobStatus(job, 'Rejected'),
              ),
              const SizedBox(height: 24),
              // ── Profile verification panel (still mock) ───────
              _VerificationPanel(
                onVerifyJobSeeker: _verifyJobSeekerProfile,
                onFlagJobSeeker: _flagJobSeekerAccount,
                onFlagEmployer: _flagEmployerAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Job moderation table ─────────────────────────────────────────────────────

class _JobModerationTable extends StatelessWidget {
  const _JobModerationTable({
    required this.pendingJobs,
    required this.updatingIds,
    required this.onApprove,
    required this.onReject,
  });

  final List<Job> pendingJobs;
  final Set<String> updatingIds;
  final Future<void> Function(Job job) onApprove;
  final Future<void> Function(Job job) onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'Pending Job Posts',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                if (pendingJobs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${pendingJobs.length}',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Empty state ───────────────────────────────────
            if (pendingJobs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green[600],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No pending jobs at this time.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All submissions have been reviewed.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              // ── Data table ────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                  ),
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Job Title')),
                    DataColumn(label: Text('Company')),
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: pendingJobs.map((Job job) {
                    final bool isUpdating = updatingIds.contains(job.id);

                    return DataRow(
                      cells: <DataCell>[
                        DataCell(Text(job.title)),
                        DataCell(Text(job.company ?? '—')),
                        DataCell(Text(job.location ?? '—')),
                        DataCell(Text(job.type ?? '—')),
                        DataCell(
                          isUpdating
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      tooltip: 'Approve',
                                      onPressed: () => onApprove(job),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      color: Colors.green.shade700,
                                    ),
                                    IconButton(
                                      tooltip: 'Reject',
                                      onPressed: () => onReject(job),
                                      icon: const Icon(Icons.cancel_outlined),
                                      color: Colors.orange.shade800,
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

// ── Verification panel — unchanged from original ─────────────────────────────

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
    final bool hasEmployerProfile =
        MockProfileStore.employerProfile.isNotEmpty;
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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
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
                  onPressed:
                      hasJobSeekerProfile ? onVerifyJobSeeker : null,
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Mark Profile Verified'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      hasJobSeekerProfile ? onFlagJobSeeker : null,
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

// ── Status pill — unchanged from original ────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      'Approved' => Colors.green,
      'Rejected' => Colors.redAccent,
      _          => Colors.orange,
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