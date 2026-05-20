import 'package:flutter/material.dart';

import '../data/mock_job_store.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/filter_dropdown.dart';
import 'job_listing_page.dart';

class JobPostingPage extends StatefulWidget {
  const JobPostingPage({super.key});

  static const String routeName = '/job-posting';

  @override
  State<JobPostingPage> createState() => _JobPostingPageState();
}

class _JobPostingPageState extends State<JobPostingPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Saves to the mock job store and sends the user to the listing page.
  void _saveJob() {
    final String title = _titleController.text.trim();
    final String company = _companyController.text.trim();
    final String location = _locationController.text.trim();
    final String description = _descriptionController.text.trim();
    final String requirements = _requirementsController.text.trim();

    if (title.isEmpty ||
        company.isEmpty ||
        location.isEmpty ||
        description.isEmpty ||
        requirements.isEmpty) {
      _showMessage('Please complete all job posting fields.');
      return;
    }

    MockJobStore.addJob(
      title: title,
      company: company,
      location: location,
      type: _selectedJobType,
      description: description,
      requirements: requirements,
    );

    _showMessage('Job posted successfully.');
    Navigator.pushReplacementNamed(context, JobListingPage.routeName);
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
                  children: [
                    Text(
                      'Job Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CommonTextField(
                      controller: _titleController,
                      labelText: 'Job Title',
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _companyController,
                      labelText: 'Company',
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _locationController,
                      labelText: 'Location',
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
                        setState(() {
                          _selectedJobType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _descriptionController,
                      labelText: 'Description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _requirementsController,
                      labelText: 'Requirements',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    CommonButton(label: 'Save Job', onPressed: _saveJob),
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
