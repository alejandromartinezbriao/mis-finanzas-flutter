import 'dart:convert';
import 'package:flutter/material.dart';

class RecurringModel {
  final String id;
  final String title;
  final String category;
  final String currency;
  final int? dueDay;
  final double defaultAmount;
  final String type;
  final bool isCreditCard;
  final bool includedInCard;
  final String? brandLogo;
  final List<dynamic> subscriptions;
  final bool isBimonetaryPart;
  final String? baseName;
  final int orderIndex;
  final int? categoryColor; 
  final String? familyId; // NUEVO: Soporte familiar
  final DateTime updatedAt;
  final bool isDeleted;
  final String syncStatus;

  RecurringModel({
    required this.id, required this.title, required this.category,
    this.currency = 'UYU', this.dueDay, this.defaultAmount = 0.0,
    this.type = 'EXPENSE', this.isCreditCard = false, this.includedInCard = false,
    this.brandLogo, this.subscriptions = const [], this.isBimonetaryPart = false,
    this.baseName, this.orderIndex = 999, this.categoryColor,
    this.familyId, DateTime? updatedAt, this.isDeleted = false, this.syncStatus = 'synced',
  }) : updatedAt = updatedAt ?? DateTime.now();

  Color? get colorValue => categoryColor != null ? Color(categoryColor!) : null;

  factory RecurringModel.fromMap(Map<String, dynamic> data, String id) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is num) return val == 1;
      return false;
    }
    List<dynamic> parseList(dynamic val) {
      if (val is List) return val;
      if (val is String) { try { return jsonDecode(val); } catch (_) {} }
      return [];
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

    return RecurringModel(
      id: id,
      title: data['title']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Otros',
      currency: data['currency']?.toString() ?? 'UYU',
      dueDay: parseInt(data['dueDay']),
      defaultAmount: (data['defaultAmount'] ?? 0.0).toDouble(),
      type: data['type']?.toString() ?? 'EXPENSE',
      isCreditCard: parseBool(data['isCreditCard']),
      includedInCard: parseBool(data['includedInCard']),
      brandLogo: data['brandLogo']?.toString(),
      subscriptions: parseList(data['subscriptions']),
      isBimonetaryPart: parseBool(data['isBimonetaryPart']),
      baseName: data['baseName']?.toString(),
      orderIndex: parseInt(data['orderIndex']) ?? 999,
      categoryColor: parseInt(data['categoryColor']),
      familyId: data['familyId']?.toString(),
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
      isDeleted: parseBool(data['isDeleted']),
      syncStatus: data['syncStatus']?.toString() ?? 'synced',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title, 'category': category, 'currency': currency, 'dueDay': dueDay,
      'defaultAmount': defaultAmount, 'type': type, 'isCreditCard': isCreditCard,
      'includedInCard': includedInCard, 'brandLogo': brandLogo, 'subscriptions': subscriptions,
      'isBimonetaryPart': isBimonetaryPart, 'baseName': baseName, 'orderIndex': orderIndex, 
      'categoryColor': categoryColor, 'familyId': familyId,
      'updatedAt': updatedAt.toIso8601String(), 'isDeleted': isDeleted, 'syncStatus': syncStatus,
    };
  }

  Map<String, dynamic> toLocalMap() {
    final map = toMap();
    map['id'] = id;
    map['subscriptions'] = jsonEncode(subscriptions);
    map['isCreditCard'] = isCreditCard ? 1 : 0;
    map['includedInCard'] = includedInCard ? 1 : 0;
    map['isBimonetaryPart'] = isBimonetaryPart ? 1 : 0;
    map['isDeleted'] = isDeleted ? 1 : 0;
    return map;
  }
}
