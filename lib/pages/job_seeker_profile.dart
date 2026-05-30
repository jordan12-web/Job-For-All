import 'package:flutter/material.dart';

import '../data/mock_job_store.dart';
import '../data/mock_notification_store.dart';
import '../data/mock_profile_store.dart';
import '../models/job.dart';
import '../utils/matching_utils.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/verified_badge.dart';
import 'job_detail_page.dart';

class JobSeekerProfile extends StatefulWidget {
  const JobSeekerProfile({super.key});

  static const String routeName = '/job-seeker-profile';

  @override
  State<JobSeekerProfile> createState() => _JobSeekerProfileState();
}

class _JobSeekerProfileState extends State<JobSeekerProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();

  Map<String, String> _savedProfile = Map<String, String>.from(
    MockProfileStore.jobSeekerProfile,
  );

  @override
  void initState() {
    super.initState();
    _loadSavedProfileIntoForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _skillsController.dispose();
    _educationController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  void _loadSavedProfileIntoForm() {
    _nameController.text = _savedProfile['Name'] ?? '';
    _contactController.text = _savedProfile['Contact'] ?? '';
    _skillsController.text = _savedProfile['Skills'] ?? '';
    _educationController.text = _savedProfile['Education'] ?? '';
    _documentController.text = _savedProfile['Verification Document'] ?? '';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _mockUploadDocument() {
    setState(() {
      _documentController.text = 'identity_document.pdf';
    });
    _showMessage('Verification document uploaded.');
  }

  void _openJobDetails(Map<String, String> job) {
    // Convert display map to Job model so JobDetailPage receives
    // the correct type. Mock recommended jobs use Map<String,String>
    // so we construct a Job from the map fields here.
    final Job jobModel = Job(
      id: job['id'] ?? '',
      employerId: '',
      title: job['title'] ?? 'Untitled',
      description: job['description'] ?? '',
      requirements: job['requirements'] ?? '',
      location: job['location'],
      type: job['type'],
      company: job['company'],
      status: job['status'] ?? 'Approved',
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => JobDetailPage(job: jobModel),
      ),
    );
  }

  void _notifyForRecommendedJobs(String skills) {
    final List<Map<String, String>> matchedJobs = MatchingUtils.matchedJobs(
      seekerSkills: skills,
      jobs: MockJobStore.jobs,
    );

    for (final Map<String, String> job in matchedJobs) {
      MockNotificationStore.notifyIfJobMatches(job);
    }
  }

  // Saves the profile to the mock store and refreshes recommendations.
  void _saveProfile() {
    final String name = _nameController.text.trim();
    final String contact = _contactController.text.trim();
    final String skills = _skillsController.text.trim();
    final String education = _educationController.text.trim();
    final String verificationDocument = _documentController.text.trim();

    if (name.isEmpty ||
        contact.isEmpty ||
        skills.isEmpty ||
        education.isEmpty) {
      _showMessage('Please complete all job seeker profile fields.');
      return;
    }

    MockProfileStore.saveJobSeekerProfile(
      name: name,
      contact: contact,
      skills: skills,
      education: education,
      verificationDocument: verificationDocument,
    );
    _notifyForRecommendedJobs(skills);

    setState(() {
      _savedProfile = Map<String, String>.from(
        MockProfileStore.jobSeekerProfile,
      );
    });
    _showMessage('Job seeker profile saved. Recommendations updated.');
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified = _savedProfile['Verified'] == 'true';
    final String savedSkills = _savedProfile['Skills'] ?? '';
    final List<Map<String, String>> recommendedJobs = MatchingUtils.matchedJobs(
      seekerSkills: savedSkills,
      jobs: MockJobStore.jobs,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Job Seeker Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileSection(
                  title: 'Edit Profile',
                  trailing: VerifiedBadge(isVerified: isVerified),
                  children: [
                    CommonTextField(
                      controller: _nameController,
                      labelText: 'Name',
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _contactController,
                      labelText: 'Contact',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _skillsController,
                      labelText: 'Skills',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _educationController,
                      labelText: 'Education',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _documentController,
                      labelText: 'Verification Document',
                    ),
                    const SizedBox(height: 12),
                    CommonButton(
                      label: 'Upload Document',
                      icon: Icons.upload_file,
                      isPrimary: false,
                      onPressed: _mockUploadDocument,
                    ),
                    const SizedBox(height: 24),
                    CommonButton(
                      label: 'Save Profile',
                      icon: Icons.save,
                      onPressed: _saveProfile,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  title: 'Saved Profile',
                  trailing: VerifiedBadge(isVerified: isVerified),
                  children: _savedProfile.isEmpty
                      ? [const Text('No job seeker profile saved yet.')]
                      : _savedProfile.entries
                            .where(
                              (MapEntry<String, String> entry) =>
                                  entry.key != 'Verified' &&
                                  entry.key != 'Flagged',
                            )
                            .map(
                              (entry) => _ProfileInfoRow(
                                label: entry.key,
                                value: entry.value.isEmpty
                                    ? 'Not provided'
                                    : entry.value,
                              ),
                            )
                            .toList(),
                ),
                const SizedBox(height: 24),
                _RecommendedJobsSection(
                  jobs: recommendedJobs,
                  onOpenJob: _openJobDetails,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedJobsSection extends StatelessWidget {
  const _RecommendedJobsSection({required this.jobs, required this.onOpenJob});

  final List<Map<String, String>> jobs;
  final ValueChanged<Map<String, String>> onOpenJob;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Recommended Jobs',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (jobs.isEmpty)
              const Text(
                'Save skills that match job requirements to see recommendations.',
              )
            else
              ...jobs.map(
                (Map<String, String> job) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    leading: const Icon(Icons.work_outline),
                    title: Text(job['title'] ?? 'Untitled Job'),
                    subtitle: Text(
                      '${job['company'] ?? 'Unknown Company'} - ${job['location'] ?? 'Unknown Location'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onOpenJob(job),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}