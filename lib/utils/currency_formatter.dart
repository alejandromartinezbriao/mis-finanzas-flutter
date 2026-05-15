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

    // Adaptación para iPhone: Si el usuario ingresa una coma, la convertimos en punto automáticamente.
    String text = newValue.text.replaceAll(',', '.');

    // Solo permitimos dígitos y un único PUNTO para decimales.
    // Bloqueamos físicamente cualquier otra cosa para evitar errores.
    final regExp = RegExp(r'^\d*\.?\d{0,2}$');
    
    if (regExp.hasMatch(text)) {
      return TextEditingValue(
        text: text,
        selection: newValue.selection,
      );
    }

    // Si el usuario intenta poner algo no válido (como una segunda coma/punto), lo bloqueamos.
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
