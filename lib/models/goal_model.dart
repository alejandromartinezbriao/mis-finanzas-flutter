import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final String icon;
  final String? linkedAccountId;
  final String? familyId; // NUEVO: Soporte familiar
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String syncStatus;

  GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.currency,
    required this.icon,
    this.linkedAccountId,
    this.familyId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = 'synced',
  });

  factory GoalModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return GoalModel(
      id: id,
      title: data['title']?.toString() ?? '',
      targetAmount: (data['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0.0).toDouble(),
      currency: data['currency']?.toString() ?? 'UYU',
      icon: data['icon']?.toString() ?? 'flag',
      linkedAccountId: data['linkedAccountId']?.toString(),
      familyId: data['familyId']?.toString(),
      createdAt: parseTime(data['createdAt']),
      updatedAt: parseTime(data['updatedAt'] ?? data['createdAt']),
      isDeleted: data['isDeleted'] == true || data['isDeleted'] == 1,
      syncStatus: data['syncStatus']?.toString() ?? 'synced',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'currency': currency,
      'icon': icon,
      'linkedAccountId': linkedAccountId,
      'familyId': familyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
      'syncStatus': syncStatus,
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'currency': currency,
      'icon': icon,
      'linkedAccountId': linkedAccountId,
      'familyId': familyId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'syncStatus': syncStatus,
    };
  }
}
