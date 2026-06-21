import 'package:flutter/material.dart';

import '../models/pricing_plan.dart';
import '../theme/app_colors.dart';
import '../widgets/common_button.dart';
import 'home_page.dart';

/// Represents a payment method
class PaymentMethod {
  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  final String id;
  final String name;
  final IconData icon;
  final String description;
}

class JobPostingPaymentPage extends StatefulWidget {
  const JobPostingPaymentPage({
    super.key,
    required this.selectedPlan,
  });

  static const String routeName = '/job-posting-payment';

  final PricingPlan selectedPlan;

  @override
  State<JobPostingPaymentPage> createState() => _JobPostingPaymentPageState();
}

class _JobPostingPaymentPageState extends State<JobPostingPaymentPage> {
  static final List<PaymentMethod> _paymentMethods = <PaymentMethod>[
    PaymentMethod(
      id: 'telebirr',
      name: 'Telebirr',
      icon: Icons.phone_android,
      description: 'Fast and secure mobile payment',
    ),
    PaymentMethod(
      id: 'cbe_birr',
      name: 'CBE Birr',
      icon: Icons.account_balance,
      description: 'Commercial Bank of Ethiopia',
    ),
    PaymentMethod(
      id: 'chapa',
      name: 'Chapa',
      icon: Icons.credit_card,
      description: 'Multi-channel payment solution',
    ),
  ];

  String? _selectedPaymentMethodId;
  bool _isProcessing = false;

  void _selectPaymentMethod(String methodId) {
    setState(() => _selectedPaymentMethodId = methodId);
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate payment processing delay
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment successful! Your job posting is now active. '
          'Plan: ${widget.selectedPlan.name}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 4),
      ),
    );

    // Navigate back to home after short delay
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      HomePage.routeName,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Order summary
                Card(
                  color: AppColors.background,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Order Summary',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              widget.selectedPlan.name,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'ETB ${widget.selectedPlan.priceETB.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Duration',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              widget.selectedPlan.duration,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Total',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'ETB ${widget.selectedPlan.priceETB.toStringAsFixed(0)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.tertiary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Payment method selection header
                Text(
                  'Select Payment Method',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),

                const SizedBox(height: 16),

                // Payment method cards
                if (isWide)
                  Row(
                    children: <Widget>[
                      for (int i = 0; i < _paymentMethods.length; i++) ...<Widget>[
                        Expanded(
                          child: _PaymentMethodCard(
                            method: _paymentMethods[i],
                            isSelected:
                                _selectedPaymentMethodId == _paymentMethods[i].id,
                            onSelect: () =>
                                _selectPaymentMethod(_paymentMethods[i].id),
                          ),
                        ),
                        if (i < _paymentMethods.length - 1)
                          const SizedBox(width: 16),
                      ],
                    ],
                  )
                else
                  Column(
                    children: <Widget>[
                      for (int i = 0; i < _paymentMethods.length; i++) ...<Widget>[
                        _PaymentMethodCard(
                          method: _paymentMethods[i],
                          isSelected:
                              _selectedPaymentMethodId == _paymentMethods[i].id,
                          onSelect: () =>
                              _selectPaymentMethod(_paymentMethods[i].id),
                        ),
                        if (i < _paymentMethods.length - 1)
                          const SizedBox(height: 16),
                      ],
                    ],
                  ),

                const SizedBox(height: 32),

                // Process payment button
                _isProcessing
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : CommonButton(
                        label: 'Complete Payment',
                        onPressed: _processPayment,
                        icon: Icons.check_circle,
                      ),

                const SizedBox(height: 24),

                // Security notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.verified_user, color: Colors.green[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your payment is secure and encrypted. '
                          'We accept all major payment methods.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual payment method card
class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onSelect,
  });

  final PaymentMethod method;
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                method.icon,
                size: 48,
                color:
                    isSelected ? AppColors.tertiary : AppColors.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                method.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                method.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.tertiary : AppColors.border,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_off,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSelected ? 'Selected' : 'Select',
                      style: TextStyle(
                        fontSize: 12,
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
