/// Represents a pricing plan for job posting
class PricingPlan {
  const PricingPlan({
    required this.id,
    required this.name,
    required this.priceETB,
    required this.duration,
    required this.description,
    required this.features,
    required this.isPopular,
  });

  final String id;
  final String name;
  final double priceETB;
  final String duration;
  final String description;
  final List<String> features;
  final bool isPopular;

  /// Available pricing plans
  static const List<PricingPlan> allPlans = <PricingPlan>[
    PricingPlan(
      id: 'starter',
      name: 'Starter',
      priceETB: 1500,
      duration: '30 days',
      description: 'Perfect for single job postings',
      features: <String>[
        'Single 30-day job posting',
        'Basic job visibility',
        'Standard applicant notifications',
      ],
      isPopular: false,
    ),
    PricingPlan(
      id: 'growth',
      name: 'Growth',
      priceETB: 10000,
      duration: '30 days',
      description: 'Ideal for active hiring',
      features: <String>[
        'Unlimited postings for 30 days',
        'Featured job visibility',
        'Priority applicant notifications',
        'Basic analytics',
      ],
      isPopular: true,
    ),
    PricingPlan(
      id: 'enterprise',
      name: 'Enterprise',
      priceETB: 25000,
      duration: '1 year',
      description: 'Complete hiring solution',
      features: <String>[
        'Annual subscription',
        'Unlimited postings all year',
        'Advanced filtering & search',
        'Priority verification badge',
        'Dedicated support',
        'Advanced analytics & insights',
      ],
      isPopular: false,
    ),
  ];

  @override
  String toString() => 'PricingPlan($id: $name - ETB $priceETB)';
}
