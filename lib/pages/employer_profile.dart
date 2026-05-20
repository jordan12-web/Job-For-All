import 'package:flutter/material.dart';

import '../data/mock_profile_store.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';

class EmployerProfile extends StatefulWidget {
  const EmployerProfile({super.key});

  static const String routeName = '/employer-profile';

  @override
  State<EmployerProfile> createState() => _EmployerProfileState();
}

class _EmployerProfileState extends State<EmployerProfile> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Map<String, String> _savedProfile = Map<String, String>.from(
    MockProfileStore.employerProfile,
  );

  @override
  void initState() {
    super.initState();
    _loadSavedProfileIntoForm();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadSavedProfileIntoForm() {
    _companyNameController.text = _savedProfile['Company Name'] ?? '';
    _contactController.text = _savedProfile['Contact'] ?? '';
    _descriptionController.text = _savedProfile['Description'] ?? '';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Saves the profile to the mock store and refreshes the display section.
  void _saveProfile() {
    final String companyName = _companyNameController.text.trim();
    final String contact = _contactController.text.trim();
    final String description = _descriptionController.text.trim();

    if (companyName.isEmpty || contact.isEmpty || description.isEmpty) {
      _showMessage('Please complete all employer profile fields.');
      return;
    }

    MockProfileStore.saveEmployerProfile(
      companyName: companyName,
      contact: contact,
      description: description,
    );

    setState(() {
      _savedProfile = Map<String, String>.from(
        MockProfileStore.employerProfile,
      );
    });
    _showMessage('Employer profile saved.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employer Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileSection(
                  title: 'Edit Profile',
                  children: [
                    CommonTextField(
                      controller: _companyNameController,
                      labelText: 'Company Name',
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _contactController,
                      labelText: 'Contact',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _descriptionController,
                      labelText: 'Description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    CommonButton(
                      label: 'Save Profile',
                      onPressed: _saveProfile,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  title: 'Saved Profile',
                  children: _savedProfile.isEmpty
                      ? [const Text('No employer profile saved yet.')]
                      : _savedProfile.entries
                            .map(
                              (entry) => _ProfileInfoRow(
                                label: entry.key,
                                value: entry.value,
                              ),
                            )
                            .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
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
