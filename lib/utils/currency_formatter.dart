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

    // Política de "Cero Tolerancia":
    // Solo permitimos dígitos y una única COMA (,) para decimales.
    // NO permitimos puntos (.) de ningún tipo.
    
    final regExp = RegExp(r'^\d*,?\d{0,2}$');
    
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }

    // Si el usuario intenta poner un punto o una segunda coma, lo bloqueamos.
    return oldValue;
  }
}
