import 'package:flutter/material.dart';

import '../data/mock_job_store.dart';
import '../models/pricing_plan.dart';
import '../services/job_service.dart';
import '../utils/debug_logger.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/filter_dropdown.dart';
import 'home_page.dart';
import 'job_posting_payment_page.dart';

class JobPostingPage extends StatefulWidget {
  const JobPostingPage({super.key, this.selectedPlan});

  static const String routeName = '/job-posting';

  final PricingPlan? selectedPlan;

  @override
  State<JobPostingPage> createState() => _JobPostingPageState();
}

class _JobPostingPageState extends State<JobPostingPage> {
  final TextEditingController _titleController       = TextEditingController();
  final TextEditingController _companyController     = TextEditingController();
  final TextEditingController _locationController    = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();

  String _selectedJobType = MockJobStore.jobTypes.first;
  bool _isSubmitting = false;

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

  Future<void> _submitJob() async {
    // ── Validate first — no network call if fields are empty ──────────
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

    setState(() => _isSubmitting = true);

    DebugLogger.step(
      'JobPostingPage: submitting "${_titleController.text.trim()}"',
    );

    try {
      await JobService.instance.createJob(
        title:        _titleController.text.trim(),
        company:      _companyController.text.trim(),
        location:     _locationController.text.trim(),
        type:         _selectedJobType,
        description:  _descriptionController.text.trim(),
        requirements: _requirementsController.text.trim(),
      );

      DebugLogger.success('Job posting successful');

      if (!mounted) {
        return;
      }

      // Show success and navigate to payment or home
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Job submitted for review. It will appear once approved by an admin.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 4),
        ),
      );

      // If a pricing plan was selected, navigate to payment page
      if (widget.selectedPlan != null) {
        Navigator.pushNamed(
          context,
          JobPostingPaymentPage.routeName,
          arguments: widget.selectedPlan,
        );
      } else {
        // Otherwise go to home (backward compatibility)
        Navigator.pushNamedAndRemoveUntil(
          context,
          HomePage.routeName,
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      DebugLogger.error('JobPostingPage: createJob failed: $e');

      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your listing will be reviewed before it goes live.',
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
                    // ── Submit button ──────────────────────────────────────
                    // Uses CommonButton to keep styling consistent with the
                    // rest of the app — no style changes per sprint rules.
                    // Shows a spinner inside the button while submitting.
                    _isSubmitting
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : CommonButton(
                            label: 'Post Job',
                            onPressed: _submitJob,
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