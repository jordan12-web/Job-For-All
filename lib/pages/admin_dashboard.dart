import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/mock_profile_store.dart';
import '../models/employer_profile.dart' as model;
import '../models/job.dart';
import '../services/employer_service.dart';
import '../services/job_service.dart';
import '../theme/app_colors.dart';
import '../utils/debug_logger.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, this.showAppBar = true});

  static const String routeName = '/admin-dashboard';

  final bool showAppBar;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Job> _pendingJobs     = <Job>[];
  bool      _isLoading       = true;
  String?   _loadError;

  // Analytics counters
  int _totalSeekers      = 0;
  int _totalPendingJobs  = 0;
  int _totalApplications = 0;
  bool _analyticsLoading = true;

  final Set<String> _updatingIds = <String>{};

  // ── Employer verification queue ───────────────────────────────────────
  List<model.EmployerProfile> _pendingVerifications = <model.EmployerProfile>[];
  bool _isLoadingVerifications = true;
  String? _verificationLoadError;
  final Set<String> _verifyingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait(<Future<void>>[
      _loadDashboard(),
      _loadAnalytics(),
      _loadVerificationQueue(),
    ]);
  }

  Future<void> _loadVerificationQueue() async {
    setState(() {
      _isLoadingVerifications = true;
      _verificationLoadError  = null;
    });

    try {
      DebugLogger.step('AdminDashboard: loading verification queue');
      final List<model.EmployerProfile> pending =
          await EmployerService.instance.fetchPendingVerifications();

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingVerifications  = pending;
        _isLoadingVerifications = false;
      });
    } catch (e) {
      DebugLogger.error('Verification queue load failed: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingVerifications = false;
        _verificationLoadError  =
            'Could not load verification requests. Pull down to retry.';
      });
    }
  }

  Future<void> _approveVerification(model.EmployerProfile employer) async {
    if (_verifyingIds.contains(employer.id)) {
      return;
    }

    final bool confirmed = await _confirmAction(
      title: 'Approve verification?',
      message:
          '"${employer.companyName}" will be marked as a verified '
          'business and can publish live job postings.',
      confirmLabel: 'Approve',
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _verifyingIds.add(employer.id));

    final bool success = await EmployerService.instance.setVerified(
      employerId: employer.id,
      verified: true,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _verifyingIds.remove(employer.id);
      if (success) {
        _pendingVerifications.removeWhere(
          (model.EmployerProfile e) => e.id == employer.id,
        );
      }
    });

    _showMessage(
      success
          ? '${employer.companyName} approved and verified.'
          : 'Failed to approve verification.',
      isError: !success,
    );
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _loadError  = null;
    });

    try {
      DebugLogger.step('AdminDashboard: loading pending jobs');
      final List<Job> jobs = await JobService.instance.fetchPendingJobs();

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingJobs = jobs;
        _isLoading   = false;
      });
    } catch (e) {
      DebugLogger.error('AdminDashboard load failed: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading  = false;
        _loadError  = 'Could not load pending jobs. Pull down to retry.';
      });
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _analyticsLoading = true);

    try {
      final SupabaseClient client = Supabase.instance.client;

      // Parallel fetch of all three counts
      final List<dynamic> results = await Future.wait(<Future<dynamic>>[
        client
            .from('users')
            .select('id')
            .eq('role', 'seeker'),
        client
            .from('jobs')
            .select('id')
            .eq('status', 'Pending'),
        client
            .from('applications')
            .select('id'),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _totalSeekers      = (results[0] as List<dynamic>).length;
        _totalPendingJobs  = (results[1] as List<dynamic>).length;
        _totalApplications = (results[2] as List<dynamic>).length;
        _analyticsLoading  = false;
      });

      DebugLogger.success(
        'Analytics: seekers=$_totalSeekers pending=$_totalPendingJobs apps=$_totalApplications',
      );
    } catch (e) {
      DebugLogger.error('Analytics fetch failed: $e');
      if (!mounted) {
        return;
      }
      setState(() => _analyticsLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
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

    final String label   = newStatus == 'Approved' ? 'Approve' : 'Reject';
    final String message = newStatus == 'Approved'
        ? '"${job.title}" will become visible to job seekers.'
        : 'Employers will need to revise "${job.title}".';

    final bool confirmed = await _confirmAction(
      title:        '$label job post?',
      message:      message,
      confirmLabel: label,
      confirmColor: newStatus == 'Rejected' ? Colors.orange.shade800 : null,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _updatingIds.add(job.id));

    final bool success = await JobService.instance.updateJobStatus(
      jobId:  job.id,
      status: newStatus,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _updatingIds.remove(job.id);
      if (success) {
        _pendingJobs.removeWhere((Job j) => j.id == job.id);
        // Refresh analytics count too
        _totalPendingJobs = (_totalPendingJobs - 1).clamp(0, 999);
      }
    });

    _showMessage(
      success
          ? 'Job ${newStatus.toLowerCase()} successfully.'
          : 'Failed to update job status.',
      isError: !success,
    );
  }

  // ── Mock profile actions — unchanged ────────────────────────────────────────

  Future<void> _verifyJobSeekerProfile() async {
    final bool ok = await _confirmAction(
      title: 'Verify job seeker?',
      message: 'Mark this profile as credential-verified for employers.',
      confirmLabel: 'Verify',
    );
    if (!ok) {
      return;
    }
    setState(MockProfileStore.markJobSeekerVerified);
    _showMessage('Job seeker profile marked as verified.');
  }

  Future<void> _flagJobSeekerAccount() async {
    final bool ok = await _confirmAction(
      title: 'Flag job seeker account?',
      message: 'The account will be marked for admin review.',
      confirmLabel: 'Flag account',
      confirmColor: Colors.orange.shade800,
    );
    if (!ok) {
      return;
    }
    setState(MockProfileStore.flagJobSeekerAccount);
    _showMessage('Job seeker account flagged.');
  }

  Future<void> _flagEmployerAccount() async {
    final bool ok = await _confirmAction(
      title: 'Flag employer account?',
      message: 'The employer profile will be marked for admin review.',
      confirmLabel: 'Flag account',
      confirmColor: Colors.orange.shade800,
    );
    if (!ok) {
      return;
    }
    setState(MockProfileStore.flagEmployerAccount);
    _showMessage('Employer account flagged.');
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = RefreshIndicator(
      onRefresh: _loadAll,
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
    if (_isLoading && _analyticsLoading) {
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
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _loadAll,
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
              // ── Page header ───────────────────────────────
              Text(
                'Admin Moderation',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Review listings, verify profiles, and keep the platform trustworthy.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // ── Analytics summary ─────────────────────────
              _AnalyticsSummary(
                isLoading:         _analyticsLoading,
                totalSeekers:      _totalSeekers,
                totalPendingJobs:  _totalPendingJobs,
                totalApplications: _totalApplications,
              ),
              const SizedBox(height: 24),

              // ── Job moderation table ──────────────────────
              _JobModerationTable(
                pendingJobs: _pendingJobs,
                updatingIds: _updatingIds,
                onApprove:   (Job job) => _updateJobStatus(job, 'Approved'),
                onReject:    (Job job) => _updateJobStatus(job, 'Rejected'),
              ),
              const SizedBox(height: 24),

              // ── Employer verification requests (real Supabase data) ──
              _VerificationRequestsPanel(
                isLoading:    _isLoadingVerifications,
                loadError:    _verificationLoadError,
                pending:      _pendingVerifications,
                verifyingIds: _verifyingIds,
                onApprove:    _approveVerification,
                onRetry:      _loadVerificationQueue,
              ),
              const SizedBox(height: 24),

              // ── Verification panel (mock — job seeker docs) ───
              _VerificationPanel(
                onVerifyJobSeeker: _verifyJobSeekerProfile,
                onFlagJobSeeker:   _flagJobSeekerAccount,
                onFlagEmployer:    _flagEmployerAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Analytics summary ────────────────────────────────────────────────────────

class _AnalyticsSummary extends StatelessWidget {
  const _AnalyticsSummary({
    required this.isLoading,
    required this.totalSeekers,
    required this.totalPendingJobs,
    required this.totalApplications,
  });

  final bool isLoading;
  final int  totalSeekers;
  final int  totalPendingJobs;
  final int  totalApplications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Platform Summary',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 640;

            final List<Widget> tiles = <Widget>[
              _StatTile(
                label:     'Total Job Seekers',
                value:     isLoading ? '—' : totalSeekers.toString(),
                icon:      Icons.people_outline,
                iconColor: AppColors.sky,
                bgColor:   AppColors.skyLight,
                isLoading: isLoading,
              ),
              _StatTile(
                label:     'Pending Reviews',
                value:     isLoading ? '—' : totalPendingJobs.toString(),
                icon:      Icons.pending_actions_outlined,
                iconColor: AppColors.warning,
                bgColor:   const Color(0xFFFFFBEB),
                isLoading: isLoading,
              ),
              _StatTile(
                label:     'Total Applications',
                value:     isLoading ? '—' : totalApplications.toString(),
                icon:      Icons.assignment_outlined,
                iconColor: AppColors.success,
                bgColor:   const Color(0xFFF0FDF4),
                isLoading: isLoading,
              ),
            ];

            if (wide) {
              return Row(
                children: tiles
                    .map(
                      (Widget t) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: t,
                        ),
                      ),
                    )
                    .toList()
                  ..[tiles.length - 1] = Expanded(child: tiles.last),
              );
            }

            return Column(
              children: tiles
                  .map(
                    (Widget t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: t,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        _AnalyticsChart(
          isLoading:         isLoading,
          totalSeekers:      totalSeekers,
          totalPendingJobs:  totalPendingJobs,
          totalApplications: totalApplications,
        ),
      ],
    );
  }
}

class _AnalyticsChart extends StatelessWidget {
  const _AnalyticsChart({
    required this.isLoading,
    required this.totalSeekers,
    required this.totalPendingJobs,
    required this.totalApplications,
  });

  final bool isLoading;
  final int totalSeekers;
  final int totalPendingJobs;
  final int totalApplications;

  @override
  Widget build(BuildContext context) {
    final double maxY = <double>[
      totalSeekers.toDouble(),
      totalPendingJobs.toDouble(),
      totalApplications.toDouble(),
      1,
    ].reduce((double a, double b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Activity Overview',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : BarChart(
                    BarChartData(
                      maxY: maxY * 1.2,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
                        getDrawingHorizontalLine: (double _) => FlLine(
                          color: AppColors.border,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value == meta.max || value == 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const List<String> labels = <String>[
                                'Seekers',
                                'Pending',
                                'Apps',
                              ];
                              final int index = value.toInt();
                              if (index < 0 || index >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[index],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: <BarChartGroupData>[
                        BarChartGroupData(
                          x: 0,
                          barRods: <BarChartRodData>[
                            BarChartRodData(
                              toY: totalSeekers.toDouble(),
                              color: AppColors.sky,
                              width: 28,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: <BarChartRodData>[
                            BarChartRodData(
                              toY: totalPendingJobs.toDouble(),
                              color: AppColors.warning,
                              width: 28,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 2,
                          barRods: <BarChartRodData>[
                            BarChartRodData(
                              toY: totalApplications.toDouble(),
                              color: AppColors.success,
                              width: 28,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.isLoading,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width:  48,
            height: 48,
            decoration: BoxDecoration(
              color:        bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color:      AppColors.textSecondary,
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? const SizedBox(
                        height: 20,
                        width:  40,
                        child: LinearProgressIndicator(),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize:   28,
                          fontWeight: FontWeight.w700,
                          color:      AppColors.textPrimary,
                          height:     1,
                        ),
                      ),
              ],
            ),
          ),
        ],
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

  final List<Job>      pendingJobs;
  final Set<String>    updatingIds;
  final Future<void> Function(Job) onApprove;
  final Future<void> Function(Job) onReject;

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
                      color:        Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${pendingJobs.length}',
                      style: TextStyle(
                        color:      Colors.orange.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (pendingJobs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.check_circle_outline,
                      size:  48,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No pending jobs at this time.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All submissions have been reviewed.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.navy.withValues(alpha: 0.05),
                  ),
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Job Title')),
                    DataColumn(label: Text('Company')),
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: pendingJobs.map((Job job) {
                    final bool updating = updatingIds.contains(job.id);
                    return DataRow(
                      cells: <DataCell>[
                        DataCell(Text(job.title)),
                        DataCell(Text(job.company  ?? '—')),
                        DataCell(Text(job.location ?? '—')),
                        DataCell(Text(job.type     ?? '—')),
                        DataCell(
                          updating
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      tooltip:  'Approve',
                                      onPressed: () => onApprove(job),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      color: AppColors.success,
                                    ),
                                    IconButton(
                                      tooltip:  'Reject',
                                      onPressed: () => onReject(job),
                                      icon: const Icon(Icons.cancel_outlined),
                                      color: AppColors.warning,
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

// ── Verification panel — unchanged ────────────────────────────────────────────

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
    final bool seekerExists = MockProfileStore.jobSeekerProfile.isNotEmpty;
    final bool employerExists = MockProfileStore.employerProfile.isNotEmpty;
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
                  onPressed: seekerExists ? onVerifyJobSeeker : null,
                  icon:  const Icon(Icons.verified_user),
                  label: const Text('Mark Profile Verified'),
                ),
                OutlinedButton.icon(
                  onPressed: seekerExists ? onFlagJobSeeker : null,
                  icon:  const Icon(Icons.flag_outlined),
                  label: const Text('Flag Job Seeker'),
                ),
                OutlinedButton.icon(
                  onPressed: employerExists ? onFlagEmployer : null,
                  icon:  const Icon(Icons.business_outlined),
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
// ── Employer verification requests — real Supabase data ─────────────────────

class _VerificationRequestsPanel extends StatelessWidget {
  const _VerificationRequestsPanel({
    required this.isLoading,
    required this.loadError,
    required this.pending,
    required this.verifyingIds,
    required this.onApprove,
    required this.onRetry,
  });

  final bool isLoading;
  final String? loadError;
  final List<model.EmployerProfile> pending;
  final Set<String> verifyingIds;
  final Future<void> Function(model.EmployerProfile) onApprove;
  final Future<void> Function() onRetry;

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
                  'Verification Requests',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                if (!isLoading && pending.isNotEmpty)
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
                      '${pending.length}',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Employers awaiting business registration approval.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (loadError != null)
              Column(
                children: <Widget>[
                  Icon(Icons.error_outline, size: 40, color: AppColors.error),
                  const SizedBox(height: 8),
                  Text(
                    loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              )
            else if (pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.verified_outlined,
                      size: 48,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No pending verification requests.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              ...pending.map((model.EmployerProfile employer) {
                final bool verifying = verifyingIds.contains(employer.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                employer.companyName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reg #: ${employer.businessRegistrationNumber ?? '—'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (employer.ownerEmail != null)
                                Text(
                                  employer.ownerEmail!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        verifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: () => onApprove(employer),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Approve'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}