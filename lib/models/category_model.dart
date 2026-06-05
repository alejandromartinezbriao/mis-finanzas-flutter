import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int color; 
  final String type;
  final double budgetAmount;
  final String budgetCurrency;
  final String? familyId; // NUEVO: Soporte familiar
  final DateTime updatedAt;
  final bool isDeleted;
  final String syncStatus;

  CategoryModel({
    required this.id, required this.name, required this.icon, required this.color,
    required this.type, this.budgetAmount = 0.0, this.budgetCurrency = 'UYU',
    this.familyId, DateTime? updatedAt, this.isDeleted = false, this.syncStatus = 'synced',
  }) : updatedAt = updatedAt ?? DateTime.now();

  Color get colorValue => Color(color);

  factory CategoryModel.fromMap(Map<String, dynamic> data, String id) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is num) return val == 1;
      return false;
    }
    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) {
        if (val.startsWith('#')) return int.tryParse(val.replaceFirst('#', '0xff'), radix: 16) ?? 0xFF9E9E9E;
        return int.tryParse(val) ?? 0xFF9E9E9E;
      }
      return 0xFF9E9E9E;
    }

    return CategoryModel(
      id: id,
      name: data['name']?.toString() ?? '',
      icon: data['icon']?.toString() ?? 'category',
      color: parseInt(data['color']),
      type: data['type']?.toString() ?? 'EXPENSE',
      budgetAmount: (data['budgetAmount'] ?? 0.0).toDouble(),
      budgetCurrency: data['budgetCurrency']?.toString() ?? 'UYU',
      familyId: data['familyId']?.toString(),
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
      isDeleted: parseBool(data['isDeleted']),
      syncStatus: data['syncStatus']?.toString() ?? 'synced',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name, 'icon': icon, 'color': color, 'type': type,
      'budgetAmount': budgetAmount, 'budgetCurrency': budgetCurrency,
      'familyId': familyId,
      'updatedAt': updatedAt.toIso8601String(), 'isDeleted': isDeleted, 'syncStatus': syncStatus,
    };
  }

  Map<String, dynamic> toLocalMap() {
    final map = toMap();
    map['id'] = id;
    map['isDeleted'] = isDeleted ? 1 : 0;
    return map;
  }
}
