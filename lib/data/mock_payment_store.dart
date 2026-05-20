class MockPaymentStore {
  MockPaymentStore._();

  // Transactions are stored in memory until a real payment backend is added.
  static final List<Map<String, String>> transactions = <Map<String, String>>[];

  static void addTransaction({
    required String item,
    required String amount,
    required String status,
  }) {
    transactions.add(<String, String>{
      'date': DateTime.now().toIso8601String().split('T').first,
      'item': item,
      'amount': amount,
      'status': status,
    });
  }
}
