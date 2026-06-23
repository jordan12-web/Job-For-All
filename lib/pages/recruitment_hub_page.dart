import 'package:flutter/material.dart';

import '../data/mock_job_store.dart';
import '../models/job.dart';
import '../services/application_service.dart';
import '../services/job_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/debug_logger.dart';
import '../utils/role_utils.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/filter_dropdown.dart';
import 'job_posting_detail_page.dart';

/// Sprint 2: Recruitment Hub — replaces the old single "Post Job" tab.
///
/// Two sub-tabs:
///  - Create Job: the existing job-creation form, now with a real
///    "Save as Draft" action (status='Draft') alongside the normal
///    submit (status='Pending').
///  - My Postings: every job this employer has created (Draft,
///    Pending, Approved, Rejected), each row showing title, status,
///    and an applicant counter.
///
/// New file — does not modify job_posting_page.dart or any other
/// existing page. HomePage's tab switch can point 'postJob' at this
/// widget instead, or keep job_posting_page.dart untouched and add
/// this as an additional tab — see the Sprint 2 handoff notes for the
/// one-line change required in home_page.dart.
class RecruitmentHubPage extends StatefulWidget {
  const RecruitmentHubPage({super.key, this.showAppBar = true});

  static const String routeName = '/recruitment-hub';

  final bool showAppBar;

  @override
  State<RecruitmentHubPage> createState() => _RecruitmentHubPageState();
}

class _RecruitmentHubPageState extends State<RecruitmentHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = Column(
      children: <Widget>[
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.tertiary,
            unselectedLabelColor: AppColors.secondary,
            indicatorColor: AppColors.tertiary,
            tabs: const <Widget>[
              Tab(text: 'Create Job', icon: Icon(Icons.add_circle_outline)),
              Tab(text: 'My Postings', icon: Icon(Icons.list_alt_outlined)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const <Widget>[
              _CreateJobTab(),
              _MyPostingsTab(),
            ],
          ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Recruitment Hub')),
      body: body,
    );
  }
}

// ── Create Job tab ─────────────────────────────────────────────────────────

class _CreateJobTab extends StatefulWidget {
  const _CreateJobTab();

  @override
  State<_CreateJobTab> createState() => _CreateJobTabState();
}

class _CreateJobTabState extends State<_CreateJobTab> {
  final TextEditingController _titleController        = TextEditingController();
  final TextEditingController _companyController      = TextEditingController();
  final TextEditingController _locationController     = TextEditingController();
  final TextEditingController _descriptionController  = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();

  final FocusNode _titleFocus        = FocusNode();
  final FocusNode _companyFocus      = FocusNode();
  final FocusNode _locationFocus     = FocusNode();
  final FocusNode _descriptionFocus  = FocusNode();
  final FocusNode _requirementsFocus = FocusNode();

  String _selectedJobType = MockJobStore.jobTypes.first;
  bool _isSubmitting = false;
  bool _isSavingDraft = false;

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _titleFocus.dispose();
    _companyFocus.dispose();
    _locationFocus.dispose();
    _descriptionFocus.dispose();
    _requirementsFocus.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_titleController.text.trim().isEmpty) {
      return 'Job title is required.';
    }
    if (_companyController.text.trim().isEmpty) {
      return 'Company name is required.';
    }
    if (_locationController.text.trim().isEmpty) {
      return 'Location is required.';
    }
    if (_descriptionController.text.trim().isEmpty) {
      return 'Description is required.';
    }
    if (_requirementsController.text.trim().isEmpty) {
      return 'Requirements are required.';
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _clearForm() {
    _titleController.clear();
    _companyController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _requirementsController.clear();
    setState(() => _selectedJobType = MockJobStore.jobTypes.first);
  }

  Future<void> _submit({required bool asDraft}) async {
    final String? validationError = _validate();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    setState(() {
      if (asDraft) {
        _isSavingDraft = true;
      } else {
        _isSubmitting = true;
      }
    });

    DebugLogger.step(
      'RecruitmentHub: ${asDraft ? "saving draft" : "submitting"} '
      '"${_titleController.text.trim()}"',
    );

    try {
      if (asDraft) {
        await JobService.instance.createDraft(
          title:        _titleController.text.trim(),
          company:      _companyController.text.trim(),
          location:     _locationController.text.trim(),
          type:         _selectedJobType,
          description:  _descriptionController.text.trim(),
          requirements: _requirementsController.text.trim(),
        );
      } else {
        await JobService.instance.createJob(
          title:        _titleController.text.trim(),
          company:      _companyController.text.trim(),
          location:     _locationController.text.trim(),
          type:         _selectedJobType,
          description:  _descriptionController.text.trim(),
          requirements: _requirementsController.text.trim(),
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asDraft
                ? 'Draft saved. Find it under "My Postings".'
                : 'Job submitted for review. It will appear once approved.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 4),
        ),
      );

      _clearForm();
    } catch (e) {
      DebugLogger.error('RecruitmentHub submit failed: $e');
      if (!mounted) {
        return;
      }
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSavingDraft = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool anyBusy = _isSubmitting || _isSavingDraft;
    final double pad = AppTheme.layoutOf(context).pagePadding;
    final double gap = AppTheme.layoutOf(context).fieldSpacing;

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Job Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save a draft to finish later, or submit for admin review.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: gap + 4),
                  CommonTextField(
                    controller: _titleController,
                    labelText: 'Job Title *',
                    enabled: !anyBusy,
                    focusNode: _titleFocus,
                    nextFocusNode: _companyFocus,
                  ),
                  SizedBox(height: gap),
                  CommonTextField(
                    controller: _companyController,
                    labelText: 'Company *',
                    enabled: !anyBusy,
                    focusNode: _companyFocus,
                    nextFocusNode: _locationFocus,
                  ),
                  SizedBox(height: gap),
                  CommonTextField(
                    controller: _locationController,
                    labelText: 'Location *',
                    enabled: !anyBusy,
                    focusNode: _locationFocus,
                    nextFocusNode: _descriptionFocus,
                  ),
                  SizedBox(height: gap),
                  FilterDropdown(
                    labelText: 'Job Type',
                    value: _selectedJobType,
                    options: MockJobStore.jobTypes,
                    onChanged: (String? value) {
                      if (anyBusy || value == null) {
                        return;
                      }
                      setState(() => _selectedJobType = value);
                    },
                  ),
                  SizedBox(height: gap),
                  CommonTextField(
                    controller: _descriptionController,
                    labelText: 'Description *',
                    maxLines: 4,
                    enabled: !anyBusy,
                    focusNode: _descriptionFocus,
                    nextFocusNode: _requirementsFocus,
                  ),
                  SizedBox(height: gap),
                  CommonTextField(
                    controller: _requirementsController,
                    labelText: 'Requirements *',
                    maxLines: 4,
                    enabled: !anyBusy,
                    focusNode: _requirementsFocus,
                    onSubmitted: () => _submit(asDraft: false),
                  ),
                  SizedBox(height: gap + 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              anyBusy ? null : () => _submit(asDraft: true),
                          icon: _isSavingDraft
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSavingDraft ? 'Saving…' : 'Save as Draft',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CommonButton(
                          label: _isSubmitting ? 'Submitting…' : 'Submit for Review',
                          icon: Icons.send,
                          onPressed: anyBusy ? null : () => _submit(asDraft: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── My Postings tab ────────────────────────────────────────────────────────

class _MyPostingsTab extends StatefulWidget {
  const _MyPostingsTab();

  @override
  State<_MyPostingsTab> createState() => _MyPostingsTabState();
}

class _MyPostingsTabState extends State<_MyPostingsTab> {
  List<Job> _jobs = <Job>[];
  Map<String, int> _applicantCounts = <String, int>{};
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPostings();
  }

  Future<void> _loadPostings() async {
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
      DebugLogger.step('MyPostings: loading for employerId=$employerId');

      final List<Job> jobs =
          await JobService.instance.fetchJobsByEmployer(employerId);

      final Map<String, int> counts =
          await ApplicationService.instance.countApplicationsForJobs(
        jobs.map((Job j) => j.id).toList(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _jobs = jobs;
        _applicantCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      DebugLogger.error('MyPostings load failed: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load your postings. Pull down to retry.';
      });
    }
  }

  void _openDetail(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => JobPostingDetailPage(job: job),
      ),
    ).then((_) => _loadPostings()); // refresh counts/status on return
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Approved' => AppColors.tertiary,
      'Rejected' => AppColors.error,
      'Draft'    => AppColors.secondary,
      _          => Colors.orange.shade700, // Pending
    };
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadPostings,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
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
              onPressed: _loadPostings,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: <Widget>[
          Icon(Icons.work_off_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'You haven\'t created any job postings yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

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
            children: _jobs.map((Job job) {
              final int count = _applicantCounts[job.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openDetail(job),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  job.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(job.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    job.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor(job.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.groups_outlined,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$count applicant${count == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}