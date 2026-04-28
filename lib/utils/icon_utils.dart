import 'package:flutter/material.dart';

class IconUtils {
  static IconData getIconData(String? name) {
    switch (name) {
      case 'shopping_cart': return Icons.shopping_cart;
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'home': return Icons.home;
      case 'flash_on': return Icons.flash_on;
      case 'water_drop': return Icons.water_drop;
      case 'phone_android': return Icons.phone_android;
      case 'medical_services': return Icons.medical_services;
      case 'school': return Icons.school;
      case 'fitness_center': return Icons.fitness_center;
      case 'flight': return Icons.flight;
      case 'movie': return Icons.movie;
      case 'payments': return Icons.payments;
      case 'account_balance': return Icons.account_balance;
      case 'redeem': return Icons.redeem;
      case 'pets': return Icons.pets;
      case 'work': return Icons.work;
      case 'sports_esports': return Icons.sports_esports;
      case 'stroller': return Icons.stroller;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'flag': return Icons.flag;
      case 'category': return Icons.category;
      default: return Icons.category;
    }
  }
}
