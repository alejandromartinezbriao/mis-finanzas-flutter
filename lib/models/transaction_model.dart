import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final double? minimumAmount;
  final DateTime date;
  final DateTime? dueDate;
  final String category;
  final String currency;
  final bool isCompleted;
  final String type;
  final String? brandLogo;
  final bool includedInCard;
  final String? paidFromAccountId;
  final String? templateId; // Nuevo campo agregado
  final int orderIndex;

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
    this.brandLogo,
    this.includedInCard = false,
    this.paidFromAccountId,
    this.templateId, // Nuevo campo agregado
    this.orderIndex = 999,
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
      brandLogo: data['brandLogo'],
      includedInCard: data['includedInCard'] ?? false,
      paidFromAccountId: data['paidFromAccountId'],
      templateId: data['templateId'], // Nuevo campo agregado
      orderIndex: data['orderIndex'] ?? 999,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'amount': double.parse(amount.toStringAsFixed(2)),
      'minimumAmount': minimumAmount != null ? double.parse(minimumAmount!.toStringAsFixed(2)) : null,
      'date': Timestamp.fromDate(date),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'category': category,
      'currency': currency,
      'isCompleted': isCompleted,
      'isPaid': isCompleted,
      'type': type,
      'brandLogo': brandLogo,
      'includedInCard': includedInCard,
      'paidFromAccountId': paidFromAccountId,
      'templateId': templateId, // Nuevo campo agregado
      'orderIndex': orderIndex,
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
    String? brandLogo,
    bool? includedInCard,
    String? paidFromAccountId,
    String? templateId, // Nuevo campo agregado
    int? orderIndex,
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
      brandLogo: brandLogo ?? this.brandLogo,
      includedInCard: includedInCard ?? this.includedInCard,
      paidFromAccountId: paidFromAccountId ?? this.paidFromAccountId,
      templateId: templateId ?? this.templateId, // Nuevo campo agregado
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
