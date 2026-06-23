import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_job_store.dart';
import '../theme/app_colors.dart';
import 'job_card.dart';
import 'job_search_bar.dart';

/// Landing job search with live suggestions as the user types.
class JobPreviewSection extends StatefulWidget {
  const JobPreviewSection({
    super.key,
    required this.onViewAllJobs,
    this.onJobSelected,
  });

  final VoidCallback onViewAllJobs;
  final void Function(Map<String, String> job)? onJobSelected;

  @override
  State<JobPreviewSection> createState() => _JobPreviewSectionState();
}

class _JobPreviewSectionState extends State<JobPreviewSection> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  List<Map<String, String>> _suggestions = <Map<String, String>>[];
  Map<String, String>? _selectedJob;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && _query.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _query = value.trim();
        _suggestions = MockJobStore.searchSuggestions(_query);
        _showSuggestions = _focusNode.hasFocus && _query.isNotEmpty;
        _selectedJob = null;
      });
    });
  }

  void _selectSuggestion(Map<String, String> job) {
    setState(() {
      _selectedJob = job;
      _searchController.text = job['title'] ?? '';
      _query = _searchController.text;
      _showSuggestions = false;
      _suggestions = <Map<String, String>>[];
    });
    _focusNode.unfocus();
    widget.onJobSelected?.call(job);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 48 : 64,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Search Jobs',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type a role, skill, or company — suggestions appear as you search.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  JobSearchBar(
                    controller: _searchController,
                    focusNode: _focusNode,
                    hintText: 'e.g. developer, logistics, Addis Ababa…',
                    onChanged: _onQueryChanged,
                    onSubmitted: (String value) {
                      if (_suggestions.isNotEmpty) {
                        _selectSuggestion(_suggestions.first);
                      }
                    },
                  ),
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    _SuggestionsPanel(
                      suggestions: _suggestions,
                      onSelected: _selectSuggestion,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _buildResults(context, isMobile),
              const SizedBox(height: 28),
              Center(
                child: OutlinedButton.icon(
                  onPressed: widget.onViewAllJobs,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Browse all jobs'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.indigo,
                    side: const BorderSide(color: AppColors.indigo),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, bool isMobile) {
    if (_query.isEmpty) {
      return _EmptyPrompt(
        icon: Icons.search,
        message: 'Start typing to see job suggestions from verified listings.',
      );
    }

    if (_selectedJob != null) {
      return JobCard(
        job: _selectedJob!,
        onTap: () {},
        onApply: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign in to apply for ${_selectedJob!['title']}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }

    if (_suggestions.isEmpty && _query.isNotEmpty) {
      return _EmptyPrompt(
        icon: Icons.work_off_outlined,
        message:
            'No matches for “$_query”. Try another keyword or browse all jobs.',
      );
    }

    return _EmptyPrompt(
      icon: Icons.touch_app_outlined,
      message: 'Select a suggestion above to preview a listing.',
    );
  }
}

class _SuggestionsPanel extends StatelessWidget {
  const _SuggestionsPanel({
    required this.suggestions,
    required this.onSelected,
  });

  final List<Map<String, String>> suggestions;
  final void Function(Map<String, String> job) onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final Map<String, String> job = suggestions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
                child: const Icon(Icons.work_outline, color: AppColors.indigo),
              ),
              title: Text(
                job['title'] ?? 'Job',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${job['company'] ?? ''} · ${job['location'] ?? ''}',
              ),
              trailing: const Icon(Icons.north_west, size: 18),
              onTap: () => onSelected(job),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.indigo, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
