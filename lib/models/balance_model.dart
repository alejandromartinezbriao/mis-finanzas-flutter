import 'package:cloud_firestore/cloud_firestore.dart';

class BalanceModel {
  final String id;
  final String accountName;
  final double amount;
  final String currency;
  final DateTime updatedAt;
  final String? brandLogo;
  final String accountType;
  final bool isBimonetaryPart;
  final String? baseName;
  final bool includeInCoverage;
  final int orderIndex;
  final bool isDeleted;
  final String syncStatus;

  BalanceModel({
    required this.id, required this.accountName, required this.amount,
    this.currency = 'UYU', required this.updatedAt, this.brandLogo,
    this.accountType = 'BANK', this.isBimonetaryPart = false, this.baseName,
    this.includeInCoverage = true, this.orderIndex = 0, this.isDeleted = false,
    this.syncStatus = 'synced',
  });

  factory BalanceModel.fromMap(Map<String, dynamic> data, String id) {
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

    return BalanceModel(
      id: id,
      accountName: data['accountName']?.toString() ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency']?.toString() ?? 'UYU',
      updatedAt: parseTime(data['updatedAt']),
      brandLogo: data['brandLogo']?.toString(),
      accountType: data['accountType']?.toString() ?? 'BANK',
      isBimonetaryPart: parseBool(data['isBimonetaryPart']),
      baseName: data['baseName']?.toString(),
      includeInCoverage: parseBool(data['includeInCoverage'] ?? true),
      orderIndex: data['orderIndex'] is num ? (data['orderIndex'] as num).toInt() : 0,
      isDeleted: parseBool(data['isDeleted']),
      syncStatus: data['syncStatus']?.toString() ?? 'synced',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountName': accountName, 'amount': amount, 'currency': currency,
      'updatedAt': Timestamp.fromDate(updatedAt), 'brandLogo': brandLogo,
      'accountType': accountType, 'isBimonetaryPart': isBimonetaryPart,
      'baseName': baseName, 'includeInCoverage': includeInCoverage,
      'orderIndex': orderIndex, 'isDeleted': isDeleted, 'syncStatus': syncStatus,
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id, 'accountName': accountName, 'amount': amount, 'currency': currency,
      'updatedAt': updatedAt.toIso8601String(), 'brandLogo': brandLogo,
      'accountType': accountType, 'isBimonetaryPart': isBimonetaryPart ? 1 : 0,
      'baseName': baseName, 'includeInCoverage': includeInCoverage ? 1 : 0,
      'orderIndex': orderIndex, 'isDeleted': isDeleted ? 1 : 0, 'syncStatus': syncStatus,
    };
  }

  BalanceModel copyWith({String? accountName, double? amount, String? currency, DateTime? updatedAt, String? brandLogo, String? accountType, bool? isBimonetaryPart, String? baseName, bool? includeInCoverage, int? orderIndex, bool? isDeleted, String? syncStatus}) {
    return BalanceModel(id: id, accountName: accountName ?? this.accountName, amount: amount ?? this.amount, currency: currency ?? this.currency, updatedAt: updatedAt ?? this.updatedAt, brandLogo: brandLogo ?? this.brandLogo, accountType: accountType ?? this.accountType, isBimonetaryPart: isBimonetaryPart ?? this.isBimonetaryPart, baseName: baseName ?? this.baseName, includeInCoverage: includeInCoverage ?? this.includeInCoverage, orderIndex: orderIndex ?? this.orderIndex, isDeleted: isDeleted ?? this.isDeleted, syncStatus: syncStatus ?? this.syncStatus);
  }
}
