import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final double? minimumAmount; // Para tarjetas (mínimo)
  final DateTime date;
  final DateTime? dueDate;    // Vencimiento
  final String category;
  final String currency;     // "UYU" o "USD"
  final bool isPaid;        // Estado de pago

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    this.minimumAmount,
    required this.date,
    this.dueDate,
    required this.category,
    this.currency = 'UYU',
    this.isPaid = false,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> data, String id) {
    return ExpenseModel(
      id: id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      minimumAmount: data['minimumAmount'] != null ? (data['minimumAmount'] as num).toDouble() : null,
      date: (data['date'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      category: data['category'] ?? 'Otros',
      currency: data['currency'] ?? 'UYU',
      isPaid: data['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'minimumAmount': minimumAmount,
      'date': Timestamp.fromDate(date),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'category': category,
      'currency': currency,
      'isPaid': isPaid,
    };
  }
}
