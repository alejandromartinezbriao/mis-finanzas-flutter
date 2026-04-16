import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String title;
  final String? description; // Nuevo campo para detalles
  final double amount;
  final double? minimumAmount;
  final DateTime date;
  final DateTime? dueDate;
  final String category;
  final String currency;
  final bool isCompleted;
  final String type;

  TransactionModel({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    this.minimumAmount,
    required this.date,
    this.dueDate,
    required this.category,
    this.currency = 'UYU',
    this.isCompleted = false,
    this.type = 'EXPENSE',
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data, String id) {
    return TransactionModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      minimumAmount: data['minimumAmount'] != null ? (data['minimumAmount'] as num).toDouble() : null,
      date: (data['date'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      category: data['category'] ?? 'Otros',
      currency: data['currency'] ?? 'UYU',
      isCompleted: data['isPaid'] ?? data['isCompleted'] ?? false,
      type: data['type'] ?? 'EXPENSE',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'amount': amount,
      'minimumAmount': minimumAmount,
      'date': Timestamp.fromDate(date),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'category': category,
      'currency': currency,
      'isCompleted': isCompleted,
      'isPaid': isCompleted,
      'type': type,
    };
  }

  TransactionModel copyWith({
    String? title,
    String? description,
    double? amount,
    double? minimumAmount,
    DateTime? date,
    DateTime? dueDate,
    String? category,
    String? currency,
    bool? isCompleted,
    String? type,
  }) {
    return TransactionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
    );
  }
}
