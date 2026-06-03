import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  final bool isPaid;
  final String type;
  final String? brandLogo;
  final int? categoryColor; 
  final bool includedInCard;
  final String? paidFromAccountId;
  final String? templateId;
  final String? subscriptionId;
  final int orderIndex;
  final DateTime updatedAt;
  final bool isDeleted;
  final String syncStatus;

  TransactionModel({
    required this.id, required this.title, this.description, required this.amount,
    this.minimumAmount, required this.date, this.dueDate, required this.category,
    this.currency = 'UYU', this.isCompleted = false, this.isPaid = false,
    this.type = 'EXPENSE', this.brandLogo, this.categoryColor, this.includedInCard = false,
    this.paidFromAccountId, this.templateId, this.subscriptionId, this.orderIndex = 999,
    DateTime? updatedAt, this.isDeleted = false, this.syncStatus = 'synced',
  }) : updatedAt = updatedAt ?? DateTime.now();

  Color? get colorValue => categoryColor != null ? Color(categoryColor!) : null;

  factory TransactionModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is num) return val == 1;
      return false;
    }
    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) {
        if (val.startsWith('#')) return int.tryParse(val.replaceFirst('#', '0xff'), radix: 16);
        return int.tryParse(val);
      }
      return null;
    }

    return TransactionModel(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString(),
      amount: (data['amount'] ?? 0.0).toDouble(),
      minimumAmount: data['minimumAmount'] != null ? (data['minimumAmount'] as num).toDouble() : null,
      date: parseTime(data['date']),
      dueDate: data['dueDate'] != null ? parseTime(data['dueDate']) : null,
      category: data['category']?.toString() ?? 'Otros',
      currency: data['currency']?.toString() ?? 'UYU',
      isCompleted: parseBool(data['isCompleted']) || parseBool(data['isPaid']),
      isPaid: parseBool(data['isPaid']),
      type: data['type']?.toString() ?? 'EXPENSE',
      brandLogo: data['brandLogo']?.toString(),
      categoryColor: parseInt(data['categoryColor']),
      includedInCard: parseBool(data['includedInCard']),
      paidFromAccountId: data['paidFromAccountId']?.toString(),
      templateId: data['templateId']?.toString(),
      subscriptionId: data['subscriptionId']?.toString(),
      orderIndex: parseInt(data['orderIndex']) ?? 999,
      updatedAt: parseTime(data['updatedAt'] ?? data['date']),
      isDeleted: parseBool(data['isDeleted']),
      syncStatus: data['syncStatus']?.toString() ?? 'synced',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title, 'description': description, 'amount': amount, 'minimumAmount': minimumAmount,
      'date': Timestamp.fromDate(date), 'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'category': category, 'currency': currency, 'isCompleted': isCompleted, 'isPaid': isPaid,
      'type': type, 'brandLogo': brandLogo, 'categoryColor': categoryColor, 'includedInCard': includedInCard,
      'paidFromAccountId': paidFromAccountId, 'templateId': templateId, 'subscriptionId': subscriptionId,
      'orderIndex': orderIndex, 'updatedAt': Timestamp.fromDate(updatedAt), 'isDeleted': isDeleted,
      'syncStatus': syncStatus,
    };
  }

  Map<String, dynamic> toLocalMap() {
    final map = toMap();
    map['id'] = id;
    map['date'] = date.toIso8601String();
    map['dueDate'] = dueDate?.toIso8601String();
    map['updatedAt'] = updatedAt.toIso8601String();
    map['isCompleted'] = isCompleted ? 1 : 0;
    map['isPaid'] = isPaid ? 1 : 0;
    map['includedInCard'] = includedInCard ? 1 : 0;
    map['isDeleted'] = isDeleted ? 1 : 0;
    return map;
  }

  TransactionModel copyWith({String? id, String? title, String? description, double? amount, double? minimumAmount, DateTime? date, DateTime? dueDate, String? category, String? currency, bool? isCompleted, bool? isPaid, String? type, String? brandLogo, int? categoryColor, bool? includedInCard, String? paidFromAccountId, String? templateId, String? subscriptionId, int? orderIndex, DateTime? updatedAt, bool? isDeleted, String? syncStatus}) {
    return TransactionModel(id: id ?? this.id, title: title ?? this.title, description: description ?? this.description, amount: amount ?? this.amount, minimumAmount: minimumAmount ?? this.minimumAmount, date: date ?? this.date, dueDate: dueDate ?? this.dueDate, category: category ?? this.category, currency: currency ?? this.currency, isCompleted: isCompleted ?? this.isCompleted, isPaid: isPaid ?? this.isPaid, type: type ?? this.type, brandLogo: brandLogo ?? this.brandLogo, categoryColor: categoryColor ?? this.categoryColor, includedInCard: includedInCard ?? this.includedInCard, paidFromAccountId: paidFromAccountId ?? this.paidFromAccountId, templateId: templateId ?? this.templateId, subscriptionId: subscriptionId ?? this.subscriptionId, orderIndex: orderIndex ?? this.orderIndex, updatedAt: updatedAt ?? this.updatedAt, isDeleted: isDeleted ?? this.isDeleted, syncStatus: syncStatus ?? this.syncStatus);
  }
}
