import 'package:flutter/material.dart';

import '../data/mock_job_store.dart';
import '../utils/debug_logger.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/filter_dropdown.dart';
import 'pricing_page.dart';

/// Plain data holder for a job draft — collected here, never written
/// to the database. The draft is only persisted after payment succeeds.
/// See [PricingPage] -> [JobPostingPaymentPage] for the rest of the flow.
class JobDraft {
  const JobDraft({
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.description,
    required this.requirements,
  });

  final String title;
  final String company;
  final String location;
  final String type;
  final String description;
  final String requirements;
}

class JobPostingPage extends StatefulWidget {
  const JobPostingPage({super.key});

  static const String routeName = '/job-posting';

  @override
  State<JobPostingPage> createState() => _JobPostingPageState();
}

class _JobPostingPageState extends State<JobPostingPage> {
  final TextEditingController _titleController        = TextEditingController();
  final TextEditingController _companyController      = TextEditingController();
  final TextEditingController _locationController     = TextEditingController();
  final TextEditingController _descriptionController  = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();

  String _selectedJobType = MockJobStore.jobTypes.first;

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  /// Client-side validation — returns an error message or null if valid.
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

  /// ── GATEKEEPER STEP 1 ──────────────────────────────────────────────
  /// This NO LONGER calls JobService.createJob(). It only validates the
  /// form, builds a [JobDraft], and hands it to PricingPage. Nothing
  /// touches the database until PaymentPage confirms success.
  void _continueToPricing() {
    final String? validationError = _validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final JobDraft draft = JobDraft(
      title:        _titleController.text.trim(),
      company:      _companyController.text.trim(),
      location:     _locationController.text.trim(),
      type:         _selectedJobType,
      description:  _descriptionController.text.trim(),
      requirements: _requirementsController.text.trim(),
    );

    DebugLogger.step(
      'JobPostingPage: draft ready, routing to PricingPage. title="${draft.title}"',
    );

    Navigator.pushNamed(
      context,
      PricingPage.routeName,
      arguments: draft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Job Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Next, you\'ll choose a plan and complete payment '
                      'before this listing goes live.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    CommonTextField(
                      controller: _titleController,
                      labelText: 'Job Title *',
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _companyController,
                      labelText: 'Company *',
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _locationController,
                      labelText: 'Location *',
                    ),
                    const SizedBox(height: 16),
                    FilterDropdown(
                      labelText: 'Job Type',
                      value: _selectedJobType,
                      options: MockJobStore.jobTypes,
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _selectedJobType = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _descriptionController,
                      labelText: 'Description *',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _requirementsController,
                      labelText: 'Requirements *',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 28),
                    // ── No longer "Post Job" — this only moves the user
                    //    forward to pricing. Nothing is saved yet.
                    CommonButton(
                      label: 'Continue to Pricing',
                      icon: Icons.arrow_forward,
                      onPressed: _continueToPricing,
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