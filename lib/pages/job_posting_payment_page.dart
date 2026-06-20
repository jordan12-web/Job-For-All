import 'package:flutter/material.dart';

import '../models/pricing_plan.dart';
import '../services/employer_service.dart';
import '../services/job_service.dart';
import '../theme/app_colors.dart';
import '../utils/debug_logger.dart';
import '../widgets/common_button.dart';
import 'home_page.dart';
import 'job_posting_page.dart';

/// Arguments required to reach [JobPostingPaymentPage].
/// Bundles the unsaved job draft together with the chosen plan —
/// this is the ONLY way the page can reach the data it needs to
/// perform the database insert after payment succeeds.
class JobPostingPaymentArgs {
  const JobPostingPaymentArgs({
    required this.draft,
    required this.plan,
  });

  final JobDraft draft;
  final PricingPlan plan;
}

/// Represents a payment method.
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

/// Result of a payment attempt.
/// Structured so a real Supabase/payment-gateway call can replace
/// [_PaymentGateway.charge] later without changing any caller code.
enum PaymentStatus { success, failure }

class PaymentResult {
  const PaymentResult({required this.status, this.message});

  final PaymentStatus status;
  final String? message;

  bool get isSuccess => status == PaymentStatus.success;
}

/// ── GATEKEEPER STEP 3 — the single source of truth for checkout ──────
///
/// This is the ONLY place in the app where a job posting is written to
/// Supabase. JobService.createJob() is called from exactly one call
/// site: [_handlePaymentSuccess] below, and only after
/// [_PaymentGateway.charge] returns [PaymentStatus.success].
///
/// If the user closes the app on this screen, or payment fails, NOTHING
/// is written to public.jobs. The draft only exists in memory as a
/// [JobDraft] passed through route arguments.
class JobPostingPaymentPage extends StatefulWidget {
  const JobPostingPaymentPage({super.key, required this.args});

  static const String routeName = '/job-posting-payment';

  final JobPostingPaymentArgs args;

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
  String? _errorMessage;

  void _selectPaymentMethod(String methodId) {
    setState(() {
      _selectedPaymentMethodId = methodId;
      _errorMessage = null;
    });
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

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // ── The gatekeeper check ─────────────────────────────────────────
    // _PaymentGateway.charge is the ONLY thing standing between the
    // draft and the database. It must return success before anything
    // is written.
    final PaymentResult result = await _PaymentGateway.charge(
      methodId: _selectedPaymentMethodId!,
      plan: widget.args.plan,
    );

    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      await _handlePaymentSuccess();
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = result.message ?? 'Payment failed. Please try again.';
      });
    }
  }

  /// Called ONLY after [_PaymentGateway.charge] returns success.
  /// This is the single call site for JobService.createJob() in the
  /// entire app — the actual database write the gatekeeper protects.
  Future<void> _handlePaymentSuccess() async {
    final JobDraft draft = widget.args.draft;

    DebugLogger.step(
      'Payment succeeded — now writing job to Supabase. title="${draft.title}"',
    );

    try {
      await JobService.instance.createJob(
        title:        draft.title,
        company:      draft.company,
        location:     draft.location,
        type:         draft.type,
        description:  draft.description,
        requirements: draft.requirements,
      );

      DebugLogger.success('Job created after payment confirmation');

      // Update the employer's subscription_plan now that payment is
      // confirmed. Best-effort: if this fails, the job posting itself
      // has already succeeded and should not be rolled back — we log
      // and continue rather than blocking the user on a secondary write.
      final bool subscriptionUpdated =
          await EmployerService.instance.setSubscriptionPlan(
        widget.args.plan.id,
      );
      if (!subscriptionUpdated) {
        DebugLogger.warning(
          'Job created, but failed to update subscription_plan on employers table',
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment successful! Your job posting (${widget.args.plan.name} '
            'plan) is now submitted for review.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 4),
        ),
      );

      await Future<void>.delayed(const Duration(seconds: 1));

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        HomePage.routeName,
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Payment succeeded but the DB write failed — this is the one
      // edge case worth surfacing clearly, since the user has been
      // charged. In a real gateway integration this would trigger
      // a refund or a support ticket; for now we show a clear error
      // and keep the user on this page so they can retry the insert.
      DebugLogger.error(
        'Payment succeeded but createJob failed: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _errorMessage =
            'Payment was confirmed, but we could not save your job posting. '
            'Please contact support — do not pay again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 1000;
    final PricingPlan plan = widget.args.plan;

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
                // ── Order summary ────────────────────────────────────
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
                              plan.name,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'ETB ${plan.priceETB.toStringAsFixed(0)}',
                              style: const TextStyle(
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
                              'Job',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                widget.args.draft.title,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
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
                              'ETB ${plan.priceETB.toStringAsFixed(0)}',
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
                Text(
                  'Select Payment Method',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    children: <Widget>[
                      for (int i = 0; i < _paymentMethods.length; i++) ...<Widget>[
                        Expanded(
                          child: _PaymentMethodCard(
                            method: _paymentMethods[i],
                            isSelected: _selectedPaymentMethodId ==
                                _paymentMethods[i].id,
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
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _isProcessing
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : CommonButton(
                        label: 'Process Payment',
                        onPressed: _processPayment,
                        icon: Icons.check_circle,
                      ),
                const SizedBox(height: 24),
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
                          'Your job will only be posted after payment is '
                          'confirmed. Nothing is saved until then.',
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

/// ── Payment gateway placeholder ───────────────────────────────────────
///
/// This is the single function to replace when integrating a real
/// payment provider. It currently only prints to the console and
/// simulates a delay, but its signature and return type already match
/// what a real Telebirr/CBE Birr/Chapa SDK call would need to return:
/// a [PaymentResult] with a clear success/failure status.
///
/// TODO (next sprint): replace the body of [charge] with a real HTTP
/// call to the chosen payment provider's API or a Supabase Edge
/// Function that verifies the transaction server-side.
abstract final class _PaymentGateway {
  static Future<PaymentResult> charge({
    required String methodId,
    required PricingPlan plan,
  }) async {
    // ── Mock processing delay ───────────────────────────────────────
    await Future<void>.delayed(const Duration(seconds: 2));

    // ── Mock console-only "payment processed" log ───────────────────
    // ignore: avoid_print
    print(
      'Payment Processed — method=$methodId plan=${plan.id} '
      'amount=ETB ${plan.priceETB.toStringAsFixed(0)}',
    );

    DebugLogger.success(
      'Mock payment processed: $methodId / ${plan.name} / '
      'ETB ${plan.priceETB.toStringAsFixed(0)}',
    );

    // Mock gateway always succeeds for now.
    return const PaymentResult(status: PaymentStatus.success);
  }
}

/// Individual payment method card — unchanged visually from the
/// existing implementation already confirmed working.
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
                color: isSelected ? AppColors.tertiary : AppColors.secondary,
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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