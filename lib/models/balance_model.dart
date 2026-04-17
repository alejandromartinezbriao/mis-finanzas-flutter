import 'package:cloud_firestore/cloud_firestore.dart';

class BalanceModel {
  final String id;
  final String accountName;
  final double amount;
  final String currency;
  final DateTime updatedAt;
  final String? brandLogo;

  BalanceModel({
    required this.id,
    required this.accountName,
    required this.amount,
    this.currency = 'UYU',
    required this.updatedAt,
    this.brandLogo,
  });

  factory BalanceModel.fromMap(Map<String, dynamic> data, String id) {
    return BalanceModel(
      id: id,
      accountName: data['accountName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'UYU',
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      brandLogo: data['brandLogo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountName': accountName,
      'amount': amount,
      'currency': currency,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'brandLogo': brandLogo,
    };
  }

  BalanceModel copyWith({
    String? accountName,
    double? amount,
    String? currency,
    DateTime? updatedAt,
    String? brandLogo,
  }) {
    return BalanceModel(
      id: id,
      accountName: accountName ?? this.accountName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
      brandLogo: brandLogo ?? this.brandLogo,
    );
  }
}
