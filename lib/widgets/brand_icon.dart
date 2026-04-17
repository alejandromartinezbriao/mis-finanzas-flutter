import 'package:flutter/material.dart';

class BrandIcon extends StatelessWidget {
  final String name;
  final String? manualLogo; // Nuevo campo para logo manual
  final double size;

  const BrandIcon({
    super.key,
    required this.name,
    this.manualLogo,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final String label = name.toLowerCase();
    
    // Mapeo de palabras clave a la ruta del asset
    String? assetPath = manualLogo != null ? 'assets/logos/$manualLogo' : null;

    if (assetPath == null) {
      if (label.contains('santander')) {
        assetPath = 'assets/logos/santander.png';
      } else if (label.contains('itau') || label.contains('itaú')) {
        assetPath = 'assets/logos/itau.png';
      } else if (label.contains('bbva')) {
        assetPath = 'assets/logos/bbva.png';
      } else if (label.contains('scotia')) {
        assetPath = 'assets/logos/scotiabank.png';
      } else if (label.contains('republica') || label.contains('brou')) {
        assetPath = 'assets/logos/banco-republica.png';
      } else if (label.contains('oca')) {
        assetPath = 'assets/logos/oca.png';
      } else if (label.contains('cabal')) {
        assetPath = 'assets/logos/cabal.png';
      } else if (label.contains('ose')) {
        assetPath = 'assets/logos/ose.png';
      } else if (label.contains('ute')) {
        assetPath = 'assets/logos/ute.png';
      } else if (label.contains('imm') || label.contains('intendencia') || label.contains('montevideo')) {
        assetPath = 'assets/logos/imm.png';
      } else if (label.contains('ces')) {
        assetPath = 'assets/logos/ces.png';
      } else if (label.contains('alquiler')) {
        assetPath = 'assets/logos/alquiler.png';
      } else if (label.contains('comunes')) {
        assetPath = 'assets/logos/gastos-comunes.png';
      }
    }

    Widget content;
    if (assetPath != null) {
      content = Image.asset(
        assetPath,
        width: size * 0.7,
        height: size * 0.7,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _defaultIcon(label),
      );
    } else {
      content = _defaultIcon(label);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: content,
      ),
    );
  }

  Widget _defaultIcon(String label) {
    IconData iconData = Icons.account_balance_wallet;
    Color color = Colors.grey;

    if (label.contains('tarjeta') || label.contains('visa') || label.contains('master')) {
      iconData = Icons.credit_card;
      color = Colors.blueGrey;
    } else if (label.contains('ose') || label.contains('agua')) {
      iconData = Icons.water_drop;
      color = Colors.blue;
    } else if (label.contains('antel') || label.contains('teléfono')) {
      iconData = Icons.phone_android;
      color = Colors.green;
    } else if (label.contains('luz') || label.contains('ute')) {
      iconData = Icons.lightbulb;
      color = Colors.amber;
    }

    return Icon(iconData, size: size, color: color);
  }
}
