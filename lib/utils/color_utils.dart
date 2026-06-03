import 'package:flutter/material.dart';

class ColorUtils {
  static Color parse(dynamic val) {
    if (val == null) return Colors.blueGrey;
    
    try {
      if (val is int) {
        return Color(val);
      }
      
      if (val is String) {
        if (val.startsWith('#')) {
          return Color(int.parse(val.replaceFirst('#', '0xff'), radix: 16));
        }
        return Color(int.parse(val));
      }
      
      if (val is num) {
        return Color(val.toInt());
      }
    } catch (e) {
      debugPrint("Error parsing color: $val - $e");
    }
    
    return Colors.blueGrey;
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }
}
