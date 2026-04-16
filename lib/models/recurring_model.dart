class RecurringModel {
  final String id;
  final String title;
  final String category;
  final String currency;
  final int? expectedDueDay; // Día del mes (1-31) en que suele vencer

  RecurringModel({
    required this.id,
    required this.title,
    required this.category,
    this.currency = 'UYU',
    this.expectedDueDay,
  });

  factory RecurringModel.fromMap(Map<String, dynamic> data, String id) {
    return RecurringModel(
      id: id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'Otros',
      currency: data['currency'] ?? 'UYU',
      expectedDueDay: data['expectedDueDay'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'currency': currency,
      'expectedDueDay': expectedDueDay,
    };
  }
}
