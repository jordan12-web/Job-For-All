import 'package:flutter/material.dart';

// Mock stores kept for apply dialog — will be replaced in applications sprint
import '../data/mock_application_store.dart';
import '../data/mock_job_store.dart';
import '../data/mock_profile_store.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../utils/debug_logger.dart';
import '../utils/matching_utils.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/job_card.dart';
import '../widgets/job_search_bar.dart';
import 'job_detail_page.dart';

class JobListingPage extends StatefulWidget {
  const JobListingPage({super.key, this.showAppBar = true});

  static const String routeName = '/job-listing';

  final bool showAppBar;

  @override
  State<JobListingPage> createState() => _JobListingPageState();
}

class _JobListingPageState extends State<JobListingPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Job> _allJobs = <Job>[];
  String _searchKeyword = '';
  String _selectedLocation = 'All';
  String _selectedJobType = 'All';
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      DebugLogger.step('JobListingPage: fetching approved jobs from Supabase');
      final List<Job> jobs = await JobService.instance.fetchApprovedJobs();

      if (!mounted) {
        return;
      }

      DebugLogger.success('JobListingPage: loaded ${jobs.length} jobs');
      setState(() {
        _allJobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      DebugLogger.error('JobListingPage: fetch failed: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = 'Could not load jobs. Pull down to retry.';
      });
    }
  }

  // Build location filter options dynamically from fetched data
  List<String> get _locationOptions {
    final Set<String> locations = _allJobs
        .where((Job job) => job.location != null && job.location!.isNotEmpty)
        .map((Job job) => job.location!)
        .toSet();
    return <String>['All', ...locations.toList()..sort()];
  }

  List<Job> get _filteredJobs {
    return _allJobs.where((Job job) {
      final String keyword = _searchKeyword.toLowerCase();

      final bool matchesKeyword = keyword.isEmpty ||
          job.title.toLowerCase().contains(keyword) ||
          (job.company ?? '').toLowerCase().contains(keyword) ||
          job.description.toLowerCase().contains(keyword);

      final bool matchesLocation =
          _selectedLocation == 'All' || job.location == _selectedLocation;

      final bool matchesType =
          _selectedJobType == 'All' || job.type == _selectedJobType;

      return matchesKeyword && matchesLocation && matchesType;
    }).toList();
  }

  // Navigate to JobDetailPage passing the full Job object
  void _openJobDetails(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => JobDetailPage(job: job),
      ),
    );
  }

  Future<void> _openApplyDialog(Job job) async {
    final bool? didApply = await showDialog<bool>(
      context: context,
      builder: (_) => _ApplyJobDialog(job: job.toDisplayMap()),
    );

    if (didApply == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application submitted for ${job.title}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = RefreshIndicator(
      onRefresh: _loadJobs,
      child: _buildBody(context),
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Listings'),
        elevation: 0,
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Loading jobs…',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _loadJobs,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final List<Job> jobs = _filteredJobs;
    final String seekerSkills =
        MockProfileStore.jobSeekerProfile['Skills'] ?? '';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Browse Opportunities',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Search verified listings from employers across Ethiopia.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              JobSearchBar(
                controller: _searchController,
                onChanged: (String value) {
                  setState(() => _searchKeyword = value.trim());
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool isWide = constraints.maxWidth >= 640;
                  final List<Widget> filters = <Widget>[
                    FilterDropdown(
                      labelText: 'Location',
                      value: _selectedLocation,
                      options: _locationOptions,
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _selectedLocation = value);
                      },
                    ),
                    FilterDropdown(
                      labelText: 'Job Type',
                      value: _selectedJobType,
                      // Use MockJobStore.jobTypes so the filter stays in sync
                      // with the job types defined in the system
                      options: <String>['All', ...MockJobStore.jobTypes],
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _selectedJobType = value);
                      },
                    ),
                  ];

                  if (!isWide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        filters.first,
                        const SizedBox(height: 16),
                        filters.last,
                      ],
                    );
                  }

                  return Row(
                    children: <Widget>[
                      Expanded(child: filters.first),
                      const SizedBox(width: 16),
                      Expanded(child: filters.last),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              if (jobs.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.work_off_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No jobs match your search or filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...jobs.map(
                  (Job job) {
                    // Convert once for widgets that use the display-map contract
                    final Map<String, String> displayMap = job.toDisplayMap();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: JobCard(
                        job: displayMap,
                        companyLogo: MockCompanyLogo.forCompany(
                          job.company ?? 'Company',
                        ),
                        onTap: () => _openJobDetails(job),
                        onApply: () => _openApplyDialog(job),
                        isMatched: MatchingUtils.isJobMatch(
                          seekerSkills: seekerSkills,
                          job: displayMap,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Initials-based company logo widget — no styling changes, future-safe.
class MockCompanyLogo extends StatelessWidget {
  const MockCompanyLogo({
    super.key,
    required this.companyName,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String companyName;
  final Color backgroundColor;
  final Color foregroundColor;

  factory MockCompanyLogo.forCompany(String companyName) {
    final int hash = companyName.hashCode.abs();
    final List<Color> palette = <Color>[
      const Color(0xFF4C63FF),
      const Color(0xFF00897B),
      const Color(0xFF6A1B9A),
      const Color(0xFFE65100),
      const Color(0xFF1565C0),
    ];
    final Color bg = palette[hash % palette.length];
    return MockCompanyLogo(
      companyName: companyName,
      backgroundColor: bg.withValues(alpha: 0.15),
      foregroundColor: bg,
    );
  }

  String get _initials {
    final List<String> words = companyName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'JF';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.25)),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _ApplyJobDialog extends StatefulWidget {
  const _ApplyJobDialog({required this.job});

  final Map<String, String> job;

  @override
  State<_ApplyJobDialog> createState() => _ApplyJobDialogState();
}

class _ApplyJobDialogState extends State<_ApplyJobDialog> {
  final TextEditingController _cvController = TextEditingController();

  bool _useSavedProfile = MockProfileStore.jobSeekerProfile.isNotEmpty;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cvController.dispose();
    super.dispose();
  }

  void _mockUploadCv() {
    setState(() {
      _useSavedProfile = false;
      _cvController.text = 'uploaded_cv.pdf';
      _errorMessage = null;
    });
  }

  Future<void> _submitApplication() async {
    final Map<String, String> profile = MockProfileStore.jobSeekerProfile;
    final String cvReference = _cvController.text.trim();

    if (_useSavedProfile && profile.isEmpty) {
      setState(() {
        _errorMessage = 'Create a job seeker profile first or upload a CV.';
      });
      return;
    }

    if (!_useSavedProfile && cvReference.isEmpty) {
      setState(() {
        _errorMessage = 'Upload a CV or enter a CV file name/link.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // Placeholder delay — real DB insert wired in applications sprint
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) {
      return;
    }

    try {
      MockApplicationStore.addApplication(
        jobTitle: widget.job['title'] ?? 'Untitled Job',
        company: widget.job['company'] ?? 'Unknown Company',
        applicantName: _useSavedProfile
            ? profile['Name'] ?? 'Saved Profile Applicant'
            : 'CV Applicant',
        contact: _useSavedProfile
            ? profile['Contact'] ?? 'Not provided'
            : 'Provided in CV',
        source: _useSavedProfile ? 'Saved profile' : 'Uploaded CV',
        summary: _useSavedProfile
            ? 'Skills: ${profile['Skills'] ?? 'Not provided'} | Education: ${profile['Education'] ?? 'Not provided'}'
            : 'CV reference: $cvReference',
      );
      Navigator.pop(context, true);
    } catch (_) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Application failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSavedProfile = MockProfileStore.jobSeekerProfile.isNotEmpty;
    final String company = widget.job['company'] ?? 'Company';

    return AlertDialog(
      title: const Text('Apply for Job'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                MockCompanyLogo.forCompany(company),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.job['title'] ?? 'Selected job',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        company,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RadioGroup<bool>(
              groupValue: _useSavedProfile,
              onChanged: (bool? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _useSavedProfile = value;
                  _errorMessage = null;
                });
              },
              child: Column(
                children: <Widget>[
                  RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    value: true,
                    enabled: hasSavedProfile,
                    title: const Text('Use saved job seeker profile'),
                    subtitle: Text(
                      hasSavedProfile
                          ? 'Profile details will be submitted.'
                          : 'No saved profile found.',
                    ),
                  ),
                  RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    value: false,
                    title: const Text('Upload a CV'),
                    subtitle: const Text('Mock upload for local storage.'),
                  ),
                ],
              ),
            ),
            if (!_useSavedProfile) ...<Widget>[
              const SizedBox(height: 12),
              CommonTextField(
                controller: _cvController,
                labelText: 'CV file name or link',
              ),
              const SizedBox(height: 12),
              CommonButton(
                label: 'Upload CV',
                icon: Icons.upload_file,
                isPrimary: false,
                onPressed: _mockUploadCv,
              ),
            ],
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submitApplication,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_isSubmitting ? 'Submitting…' : 'Apply'),
        ),
      ],
    );
  }
}