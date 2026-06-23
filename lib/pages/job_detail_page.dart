import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/application_service.dart';
import '../services/job_service.dart';
import '../utils/debug_logger.dart';
import '../utils/role_utils.dart';

/// Displays full details for a single job and lets a seeker apply.
///
/// Receives a [Job] object from [JobListingPage] — no second network call.
/// The Apply button writes to `public.applications` via [ApplicationService].
class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key, required this.job});

  static const String routeName = '/job-detail';

  final Job job;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  // Tracks whether this seeker has already applied
  bool _hasApplied = false;
  bool _isCheckingStatus = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyApplied();
  }

  /// Check on load so the button is already in the right state
  Future<void> _checkIfAlreadyApplied() async {
    if (widget.job.id.isEmpty) {
      setState(() => _isCheckingStatus = false);
      return;
    }

    final bool applied = await ApplicationService.instance.hasApplied(
      jobId: widget.job.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _hasApplied = applied;
      _isCheckingStatus = false;
    });
  }

  Future<void> _handleApply() async {
    // RBAC guard: employers can never submit an application, even if
    // this method were somehow invoked directly (e.g. a future bug
    // re-enables the button). This check happens before any network
    // call, so an employer session can never reach ApplicationService.apply.
    if (RoleUtils.isEmployer()) {
      DebugLogger.warning('Blocked apply attempt: current role is Employer');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employers cannot apply to job postings.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_hasApplied || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    DebugLogger.step('JobDetailPage: applying for job ${widget.job.id}');

    final ApplyResult result = await ApplicationService.instance.apply(
      jobId: widget.job.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      if (result.isSuccess || result.status == ApplyStatus.alreadyApplied) {
        _hasApplied = true;
      }
    });

    // Show appropriate message based on result
    final String message = switch (result.status) {
      ApplyStatus.success => 'Application submitted for "${widget.job.title}"!',
      ApplyStatus.alreadyApplied => 'You have already applied for this job.',
      ApplyStatus.notLoggedIn => 'Please sign in to apply.',
      ApplyStatus.error =>
        result.message ?? 'Something went wrong. Please try again.',
    };

    final Color? color = switch (result.status) {
      ApplyStatus.success => Colors.green[700],
      ApplyStatus.alreadyApplied => Colors.orange[700],
      _ => Colors.red[700],
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  /// Builds the Apply button — handles all three states:
  /// checking, already applied, and ready to apply.
  /// Returns an empty widget entirely for employers — RBAC.
  Widget _buildApplyButton() {
    if (RoleUtils.isEmployer()) {
      return const SizedBox.shrink();
    }

    if (_isCheckingStatus) {
      return FilledButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Checking…'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
        ),
      );
    }

    if (_hasApplied) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Already Applied'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: Colors.green[700],
        ),
      );
    }

    return FilledButton.icon(
      onPressed: _isSubmitting ? null : _handleApply,
      icon: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send),
      label: Text(_isSubmitting ? 'Submitting…' : 'Apply Now'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details'), elevation: 0),
      // Apply button pinned at the bottom — always visible without scrolling
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: _buildApplyButton(),
        ),
      ),
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
                  children: <Widget>[
                    // ── Title ──────────────────────────────────────────────
                    Text(
                      widget.job.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    // ── Meta line ──────────────────────────────────────────
                    Text(
                      <String>[
                        if ((widget.job.company ?? '').isNotEmpty)
                          widget.job.company!,
                        if ((widget.job.location ?? '').isNotEmpty)
                          widget.job.location!,
                        if ((widget.job.type ?? '').isNotEmpty)
                          widget.job.type!,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ── Description ────────────────────────────────────────
                    _DetailSection(
                      title: 'Description',
                      body: widget.job.description,
                    ),
                    const SizedBox(height: 20),
                    // ── Requirements ───────────────────────────────────────
                    _DetailSection(
                      title: 'Requirements',
                      body: widget.job.requirements,
                    ),
                    const SizedBox(height: 32),
                    // ── Inline apply button (desktop convenience) ──────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(width: 200, child: _buildApplyButton()),
                    ),
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
      children: <Widget>[
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

/// Fetches a job by ID and wraps it in [JobDetailPage].
/// Ready for future deep-link / direct URL navigation support.
class JobDetailPageLoader extends StatefulWidget {
  const JobDetailPageLoader({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobDetailPageLoader> createState() => _JobDetailPageLoaderState();
}

class _JobDetailPageLoaderState extends State<JobDetailPageLoader> {
  Job? _job;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    try {
      final Job? job = await JobService.instance.fetchJobById(widget.jobId);
      if (!mounted) {
        return;
      }
      if (job == null) {
        setState(() {
          _isLoading = false;
          _error = 'Job not found or no longer available.';
        });
        return;
      }
      setState(() {
        _job = job;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Failed to load job details.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: Center(
          child: Text(
            _error ?? 'Job not found.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    return JobDetailPage(job: _job!);
  }
}
