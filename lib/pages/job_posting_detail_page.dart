import 'package:flutter/material.dart';

import '../models/application.dart';
import '../models/job.dart';
import '../services/application_service.dart';
import '../services/job_service.dart';
import '../theme/app_colors.dart';
import '../utils/debug_logger.dart';

/// Detail view for a single job posting, opened from
/// RecruitmentHubPage's "My Postings" list.
///
/// Shows the job's own details plus every application submitted to it
/// — reusing the same accept/reject pattern already proven in
/// ApplicantsPage, scoped to a single job instead of all of an
/// employer's jobs.
///
/// New file — does not modify applicants_page.dart.
class JobPostingDetailPage extends StatefulWidget {
  const JobPostingDetailPage({super.key, required this.job});

  final Job job;

  @override
  State<JobPostingDetailPage> createState() => _JobPostingDetailPageState();
}

class _JobPostingDetailPageState extends State<JobPostingDetailPage> {
  List<Application> _applications = <Application>[];
  bool _isLoadingApplicants = true;
  String? _loadError;
  bool _isPublishing = false;

  final Set<String> _updatingIds = <String>{};

  late Job _job; // mutable local copy so status updates reflect immediately

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    setState(() {
      _isLoadingApplicants = true;
      _loadError = null;
    });

    try {
      // Reuse fetchApplicationsForEmployer and filter client-side to this
      // job — avoids adding a third Supabase query method when the
      // employer-scoped one already exists and the dataset per employer
      // is small for a project of this size.
      final String employerId = _job.employerId;
      final List<Application> all =
          await ApplicationService.instance.fetchApplicationsForEmployer(
        employerId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _applications =
            all.where((Application a) => a.jobId == _job.id).toList();
        _isLoadingApplicants = false;
      });
    } catch (e) {
      DebugLogger.error('JobPostingDetailPage load failed: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingApplicants = false;
        _loadError = 'Could not load applicants. Pull down to retry.';
      });
    }
  }

  Future<void> _publishDraft() async {
    setState(() => _isPublishing = true);

    final bool success = await JobService.instance.publishDraft(_job.id);

    if (!mounted) {
      return;
    }

    setState(() => _isPublishing = false);

    if (success) {
      setState(() {
        _job = Job(
          id: _job.id,
          employerId: _job.employerId,
          title: _job.title,
          description: _job.description,
          requirements: _job.requirements,
          location: _job.location,
          type: _job.type,
          company: _job.company,
          status: 'Pending',
          createdAt: _job.createdAt,
        );
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Draft submitted for review.'
              : 'Failed to publish draft.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green[700] : AppColors.error,
      ),
    );
  }

  Future<void> _updateStatus(Application app, String newStatus) async {
    if (_updatingIds.contains(app.id)) {
      return;
    }

    setState(() => _updatingIds.add(app.id));

    final bool success =
        await ApplicationService.instance.updateApplicationStatus(
      applicationId: app.id,
      status: newStatus,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _updatingIds.remove(app.id);
      if (success) {
        final int index =
            _applications.indexWhere((Application a) => a.id == app.id);
        if (index != -1) {
          _applications[index] = app.copyWith(status: newStatus);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Application marked as $newStatus.'
              : 'Failed to update status.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? (newStatus == 'accepted' ? Colors.green[700] : Colors.red[700])
            : Colors.grey[800],
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Approved' => AppColors.tertiary,
      'Rejected' => AppColors.error,
      'Draft'    => AppColors.secondary,
      _          => Colors.orange.shade700,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posting Details')),
      body: RefreshIndicator(
        onRefresh: _loadApplicants,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildJobSummaryCard(context),
                  const SizedBox(height: 24),
                  Text(
                    'Applicants',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_applications.length} application'
                    '${_applications.length == 1 ? '' : 's'} received',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  _buildApplicantsList(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _job.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(_job.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _job.status,
                    style: TextStyle(
                      color: _statusColor(_job.status),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              <String>[
                if ((_job.company ?? '').isNotEmpty) _job.company!,
                if ((_job.location ?? '').isNotEmpty) _job.location!,
                if ((_job.type ?? '').isNotEmpty) _job.type!,
              ].join(' · '),
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(_job.description),
            if (_job.status == 'Draft') ...<Widget>[
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isPublishing ? null : _publishDraft,
                  icon: _isPublishing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish_outlined),
                  label: Text(_isPublishing ? 'Publishing…' : 'Publish Draft'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantsList(BuildContext context) {
    if (_isLoadingApplicants) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: <Widget>[
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(height: 8),
            Text(_loadError!, style: const TextStyle(color: AppColors.error)),
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: <Widget>[
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No applications for this posting yet.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _applications.map((Application app) {
        final bool isUpdating = _updatingIds.contains(app.id);
        final String name = app.seekerName ?? app.seekerEmail ?? 'Unknown applicant';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            if (app.seekerEmail != null)
                              Text(
                                app.seekerEmail!,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isUpdating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (app.isPending)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => _updateStatus(app, 'rejected'),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: () => _updateStatus(app, 'accepted'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Accept'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green[700],
                          ),
                        ),
                      ],
                    )
                  else
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        app.isAccepted ? 'Accepted' : 'Rejected',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: app.isAccepted
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}