import 'package:flutter/material.dart';

import '../models/employer_profile.dart' as model;
import '../models/pricing_plan.dart';
import '../services/employer_service.dart';
import '../theme/app_colors.dart';
import '../utils/debug_logger.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import 'job_posting_page.dart';

class EmployerProfile extends StatefulWidget {
  const EmployerProfile({super.key});

  static const String routeName = '/employer-profile';

  @override
  State<EmployerProfile> createState() => _EmployerProfileState();
}

class _EmployerProfileState extends State<EmployerProfile>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _contactController       = TextEditingController();
  final TextEditingController _regNumberController     = TextEditingController();

  final FocusNode _companyFocus = FocusNode();
  final FocusNode _contactFocus = FocusNode();
  final FocusNode _regFocus     = FocusNode();

  model.EmployerProfile? _profile;
  bool _isLoading  = true;
  bool _isSaving   = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyNameController.dispose();
    _contactController.dispose();
    _regNumberController.dispose();
    _companyFocus.dispose();
    _contactFocus.dispose();
    _regFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final model.EmployerProfile? profile =
          await EmployerService.instance.fetchMyProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _isLoading = false;
        if (profile != null) {
          _companyNameController.text = profile.companyName;
          _contactController.text     = profile.contactInfo;
          _regNumberController.text   =
              profile.businessRegistrationNumber ?? '';
        }
      });
    } catch (e) {
      DebugLogger.error('EmployerProfile load failed: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load your profile. Pull down to retry.';
      });
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

  Future<void> _saveProfile() async {
    final String companyName = _companyNameController.text.trim();
    final String contact     = _contactController.text.trim();
    final String regNumber   = _regNumberController.text.trim();

    if (companyName.isEmpty || contact.isEmpty) {
      _showMessage('Company name and contact are required.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final model.EmployerProfile updated =
          await EmployerService.instance.updateProfile(
        companyName: companyName,
        contactInfo: contact,
        businessRegistrationNumber: regNumber,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile  = updated;
        _isSaving = false;
      });

      // Make the verification-pending consequence explicit to the user —
      // this is the whole point of the workflow per Sprint 1.
      _showMessage(
        regNumber.isEmpty
            ? 'Profile saved.'
            : 'Profile saved. Your registration number is now pending '
              'admin verification.',
      );
    } catch (e) {
      DebugLogger.error('saveProfile failed: $e');
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer Profile'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.tertiary,
          unselectedLabelColor: AppColors.secondary,
          indicatorColor: AppColors.tertiary,
          tabs: const <Widget>[
            Tab(text: 'Profile', icon: Icon(Icons.business_outlined)),
            Tab(text: 'Subscription', icon: Icon(Icons.workspace_premium_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _buildProfileTab(),
                    _buildSubscriptionTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Profile ──────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_profile != null) _buildVerificationBanner(_profile!),
                if (_profile != null) const SizedBox(height: 20),
                _ProfileSection(
                  title: 'Company Details',
                  children: <Widget>[
                    CommonTextField(
                      controller: _companyNameController,
                      labelText: 'Company Name',
                      enabled: !_isSaving,
                      focusNode: _companyFocus,
                      nextFocusNode: _contactFocus,
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _contactController,
                      labelText: 'Contact',
                      keyboardType: TextInputType.phone,
                      enabled: !_isSaving,
                      focusNode: _contactFocus,
                      nextFocusNode: _regFocus,
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      controller: _regNumberController,
                      labelText: 'Business Registration Number',
                      hintText: 'e.g. ETB-REG-00123',
                      enabled: !_isSaving,
                      focusNode: _regFocus,
                      onSubmitted: _saveProfile,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Saving a registration number sends it for admin '
                      'verification. Your verified badge will be removed '
                      'until it is re-approved.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    _isSaving
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : CommonButton(
                            label: 'Save Profile',
                            onPressed: _saveProfile,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBanner(model.EmployerProfile profile) {
    if (profile.isVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.tertiary),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.verified, color: AppColors.tertiary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Your business is verified.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.tertiary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (profile.hasPendingVerification) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.hourglass_top, color: Colors.orange.shade800),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verification pending — an admin will review your '
                'registration number shortly.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add a business registration number to apply for verification.',
              style: TextStyle(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Subscription Hub ─────────────────────────────────────────────

  Widget _buildSubscriptionTab() {
    final model.EmployerProfile? profile = _profile;

    if (profile == null) {
      return const Center(child: Text('Profile not loaded.'));
    }

    if (!profile.hasActivePlan) {
      return _buildNoPlanState();
    }

    return _buildActivePlanState(profile);
  }

  Widget _buildNoPlanState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'No Active Subscription',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a plan to start posting jobs.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              // Reuse the same plan data as the gatekeeper pricing flow —
              // single source of truth for plan info stays in
              // pricing_plan.dart, never duplicated here.
              for (final PricingPlan plan in PricingPlan.allPlans) ...<Widget>[
                _PlanSummaryCard(plan: plan),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              CommonButton(
                label: 'Post a Job to Choose a Plan',
                icon: Icons.add_circle_outline,
                onPressed: () => Navigator.pushNamed(
                  context,
                  JobPostingPage.routeName,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Plans are selected during the job posting checkout flow.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePlanState(model.EmployerProfile profile) {
    final PricingPlan? plan = PricingPlan.allPlans
        .where((PricingPlan p) => p.id == profile.subscriptionPlan)
        .firstOrNull;

    // Placeholder billing date — real billing cycle tracking is a
    // future sprint once recurring payments are wired to a real gateway.
    final DateTime nextBilling =
        DateTime.now().add(const Duration(days: 30));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            color: AppColors.background,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.workspace_premium,
                        color: AppColors.tertiary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              plan?.name ?? profile.subscriptionPlan,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Active subscription',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _SubscriptionDetailRow(
                    label: 'Plan',
                    value: plan?.name ?? profile.subscriptionPlan,
                  ),
                  if (plan != null)
                    _SubscriptionDetailRow(
                      label: 'Price',
                      value: 'ETB ${plan.priceETB.toStringAsFixed(0)} / ${plan.duration}',
                    ),
                  _SubscriptionDetailRow(
                    label: 'Next Billing Date',
                    value:
                        '${nextBilling.year}-${nextBilling.month.toString().padLeft(2, '0')}-${nextBilling.day.toString().padLeft(2, '0')} (placeholder)',
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      JobPostingPage.routeName,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Post Another Job'),
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

// ── Shared small widgets ──────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.plan});

  final PricingPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  plan.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            'ETB ${plan.priceETB.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionDetailRow extends StatelessWidget {
  const _SubscriptionDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}