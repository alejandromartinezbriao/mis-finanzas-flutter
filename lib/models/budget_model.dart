class BudgetModel {
  final String id;
  final String categoryName;
  final double amount;
  final int month;
  final int year;
  final String currency;

  BudgetModel({
    required this.id,
    required this.categoryName,
    required this.amount,
    required this.month,
    required this.year,
    this.currency = 'UYU',
  });

  factory BudgetModel.fromMap(Map<String, dynamic> data, String id) {
    return BudgetModel(
      id: id,
      categoryName: data['categoryName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      month: data['month'] ?? DateTime.now().month,
      year: data['year'] ?? DateTime.now().year,
      currency: data['currency'] ?? 'UYU',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'amount': amount,
      'month': month,
      'year': year,
      'currency': currency,
    };
  }
}
