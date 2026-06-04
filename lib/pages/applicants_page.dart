import 'package:flutter/material.dart';

import '../models/application.dart';
import '../services/application_service.dart';
import '../utils/debug_logger.dart';
import '../utils/role_utils.dart';

class ApplicantsPage extends StatefulWidget {
  const ApplicantsPage({super.key, this.showAppBar = true});

  static const String routeName = '/applicants';

  final bool showAppBar;

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  List<Application> _applications = <Application>[];
  bool _isLoading = true;
  String? _loadError;

  // Tracks which application IDs are currently being updated
  // so we can show a spinner on just that card's buttons
  final Set<String> _updatingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final String? employerId = RoleUtils.currentUserId;

    if (employerId == null || employerId.isEmpty) {
      setState(() {
        _isLoading = false;
        _loadError = 'Could not identify your account. Please sign in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      DebugLogger.step('ApplicantsPage: loading for employerId=$employerId');

      final List<Application> apps =
          await ApplicationService.instance.fetchApplicationsForEmployer(
        employerId,
      );

      if (!mounted) {
        return;
      }

      DebugLogger.success('ApplicantsPage: loaded ${apps.length} applications');

      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    } catch (e) {
      DebugLogger.error('ApplicantsPage load failed: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = 'Could not load applications. Pull down to retry.';
      });
    }
  }

  Future<void> _updateStatus(Application application, String newStatus) async {
    if (_updatingIds.contains(application.id)) {
      return;
    }

    setState(() => _updatingIds.add(application.id));

    DebugLogger.step(
      'ApplicantsPage: updating ${application.id} → $newStatus',
    );

    final bool success =
        await ApplicationService.instance.updateApplicationStatus(
      applicationId: application.id,
      status: newStatus,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _updatingIds.remove(application.id);

      if (success) {
        // Optimistic update — replace the item in the list in-place
        final int index =
            _applications.indexWhere((Application a) => a.id == application.id);
        if (index != -1) {
          _applications[index] = application.copyWith(status: newStatus);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Application marked as $newStatus.'
              : 'Failed to update status. Please try again.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? (newStatus == 'accepted' ? Colors.green[700] : Colors.red[700])
            : Colors.grey[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = RefreshIndicator(
      onRefresh: _loadApplications,
      child: _buildBody(context),
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants'),
        elevation: 0,
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    // ── Loading ─────────────────────────────────────────────
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Loading applications…',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    // ── Error ───────────────────────────────────────────────
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _loadApplications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    // ── Empty state ─────────────────────────────────────────
    if (_applications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: <Widget>[
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No applications received yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Applications from job seekers will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }

    // ── Application list ────────────────────────────────────
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Applicants',
                style:
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_applications.length} application${_applications.length == 1 ? '' : 's'} received',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ..._applications.map(
                (Application app) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ApplicantCard(
                    application: app,
                    isUpdating: _updatingIds.contains(app.id),
                    onAccept: app.isPending
                        ? () => _updateStatus(app, 'accepted')
                        : null,
                    onReject: app.isPending
                        ? () => _updateStatus(app, 'rejected')
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.application,
    required this.isUpdating,
    this.onAccept,
    this.onReject,
  });

  final Application application;
  final bool isUpdating;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  Color _statusColor() {
    return switch (application.status) {
      'accepted' => Colors.green[700]!,
      'rejected' => Colors.red[700]!,
      _          => Colors.orange[700]!,
    };
  }

  @override
  Widget build(BuildContext context) {
    final String name =
        application.seekerName ?? application.seekerEmail ?? 'Unknown applicant';
    final String jobTitle = application.jobTitle ?? 'Unknown job';
    final String email = application.seekerEmail ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Header row ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor().withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    application.status[0].toUpperCase() +
                        application.status.substring(1),
                    style: TextStyle(
                      color: _statusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // ── Job applied for ──────────────────────────────
            Row(
              children: <Widget>[
                Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Applied for: $jobTitle',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Action buttons — only shown for pending apps ─
            if (isUpdating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (application.isPending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green[700],
                    ),
                  ),
                ],
              )
            else
              // Decided state — show who made the decision
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Icon(
                    application.isAccepted
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 18,
                    color: _statusColor(),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    application.isAccepted
                        ? 'Accepted — no further action needed'
                        : 'Rejected — no further action needed',
                    style: TextStyle(
                      color: _statusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}