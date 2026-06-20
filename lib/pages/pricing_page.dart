import 'package:flutter/material.dart';

import '../models/pricing_plan.dart';
import '../theme/app_colors.dart';
import '../widgets/common_button.dart';
import 'job_posting_page.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  static const String routeName = '/pricing';

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  String? _selectedPlanId;

  void _selectPlan(String planId) {
    setState(() => _selectedPlanId = planId);
  }

  void _proceedToJobPosting() {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pricing plan to continue'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final PricingPlan selectedPlan = PricingPlan.allPlans.firstWhere(
      (PricingPlan plan) => plan.id == _selectedPlanId,
    );

    Navigator.pushNamed(
      context,
      JobPostingPage.routeName,
      arguments: selectedPlan,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Pricing Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header
                Text(
                  'Choose Your Job Posting Plan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the plan that best fits your hiring needs',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Pricing cards
                if (isWide)
                  _buildWideLayout()
                else
                  _buildMobileLayout(),

                const SizedBox(height: 48),

                // Proceed button
                CommonButton(
                  label: 'Continue to Job Posting',
                  onPressed: _proceedToJobPosting,
                  icon: Icons.arrow_forward,
                ),

                const SizedBox(height: 24),

                // Info text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'All plans include review and approval by our team. '
                    'Your job will go live once approved.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < PricingPlan.allPlans.length; i++) ...<Widget>[
          Expanded(
            child: _PricingCard(
              plan: PricingPlan.allPlans[i],
              isSelected: _selectedPlanId == PricingPlan.allPlans[i].id,
              onSelect: () => _selectPlan(PricingPlan.allPlans[i].id),
            ),
          ),
          if (i < PricingPlan.allPlans.length - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: <Widget>[
        for (int i = 0; i < PricingPlan.allPlans.length; i++) ...<Widget>[
          _PricingCard(
            plan: PricingPlan.allPlans[i],
            isSelected: _selectedPlanId == PricingPlan.allPlans[i].id,
            onSelect: () => _selectPlan(PricingPlan.allPlans[i].id),
          ),
          if (i < PricingPlan.allPlans.length - 1) const SizedBox(height: 24),
        ],
      ],
    );
  }
}

/// Individual pricing card widget
class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.plan,
    required this.isSelected,
    required this.onSelect,
  });

  final PricingPlan plan;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.tertiary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected
            ? AppColors.background
            : Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Popular badge
              if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else
                const SizedBox(height: 0),

              if (plan.isPopular) const SizedBox(height: 12),

              // Plan name
              Text(
                plan.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                plan.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    'ETB ${plan.priceETB.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.tertiary,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '/ ${plan.duration}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Features list
              Text(
                'Includes:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),

              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plan.features
                    .map(
                      (String feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right: 10, top: 2),
                              child: Icon(
                                Icons.check_circle,
                                size: 18,
                                color: AppColors.tertiary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 24),

              // Selection indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.tertiary : AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_off,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSelected ? 'Selected' : 'Select Plan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
