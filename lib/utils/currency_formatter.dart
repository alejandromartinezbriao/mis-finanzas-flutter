import 'package:flutter/services.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Política de "Cero Tolerancia" (V2):
    // Solo permitimos dígitos y un único PUNTO (.) para decimales.
    // Bloqueamos físicamente la COMA (,) para evitar errores de interpretación.
    // No hay separadores de miles automáticos.
    
    final regExp = RegExp(r'^\d*\.?\d{0,2}$');
    
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }

    // Si el usuario intenta poner algo no válido (como una coma o segundo punto), lo bloqueamos.
    return oldValue;
  }
}

class CurrencyUtils {
  static String formatForInput(double value) {
    // Si el valor no tiene decimales significativos, lo mostramos como entero
    // de lo contrario mostramos 2 decimales exactos.
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
