import 'package:flutter/material.dart';

import '../utils/icon_utils.dart';

class BrandIcon extends StatelessWidget {
  final String name;
  final String? manualLogo; // Nuevo campo para logo manual
  final String? fallbackIcon; // Nuevo: Icono de categoría
  final Color? fallbackColor; // Nuevo: Color de categoría
  final double size;

  const BrandIcon({
    super.key,
    required this.name,
    this.manualLogo,
    this.fallbackIcon,
    this.fallbackColor,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final String label = name.toLowerCase();
    
    // Mapeo de palabras clave a la ruta del asset
    String? assetPath;
    
    if (manualLogo != null) {
      if (manualLogo!.startsWith('http')) {
        // Es una URL
      } else if (manualLogo!.endsWith('.png')) {
        assetPath = 'assets/logos/$manualLogo';
      } else {
        // Es un nombre de icono material
      }
    }

    if (assetPath == null && manualLogo == null) {
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
      } else if (label.contains('oca-blue')) {
        assetPath = 'assets/logos/oca-blue.png';
      } else if (label.contains('oca')) {
        assetPath = 'assets/logos/oca.png';
      } else if (label.contains('prex')) {
        assetPath = 'assets/logos/prex.png';
      } else if (label.contains('dinero') || label.contains('midinero')) {
        assetPath = 'assets/logos/midinero.png';
      } else if (label.contains('srpffaa') || label.contains('militar')) {
        assetPath = 'assets/logos/srpffaa.png';
      } else if (label.contains('queen')) {
        assetPath = 'assets/logos/queen.png';
      } else if (label.contains('bodyguard')) {
        assetPath = 'assets/logos/bodyguard.png';
      } else if (label.contains('ahorros')) {
        assetPath = 'assets/logos/ahorros.png';
      } else if (label.contains('cabal')) {
        assetPath = 'assets/logos/cabal.png';
      } else if (label.contains('ose')) {
        assetPath = 'assets/logos/ose.png';
      } else if (label.contains('ute')) {
        assetPath = 'assets/logos/ute.png';
      } else if (label.contains('antel')) {
        assetPath = 'assets/logos/antel.png';
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
    if (manualLogo != null && manualLogo!.startsWith('http')) {
      content = Image.network(
        manualLogo!,
        width: size * 0.8,
        height: size * 0.8,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _defaultIcon(context, label),
      );
    } else if (assetPath != null) {
      // Es un asset local
      content = Image.asset(
        assetPath,
        width: size * 0.8,
        height: size * 0.8,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _defaultIcon(context, label),
      );
    } else if (manualLogo != null && !manualLogo!.endsWith('.png')) {
      // Es un icono material
      content = Icon(
        IconUtils.getIconData(manualLogo),
        size: size * 0.7,
        color: fallbackColor ?? Theme.of(context).colorScheme.primary, // CORREGIDO: Usa el color de la categoría
      );
    } else {
      content = _defaultIcon(context, label);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
          center: const Alignment(-0.3, -0.3),
          radius: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.1),
          ),
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: size * 0.08,
              offset: Offset(-size * 0.05, -size * 0.05),
              spreadRadius: -1,
            ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.15),
          child: content,
        ),
      ),
    );
  }

  Widget _defaultIcon(BuildContext context, String label) {
    if (fallbackIcon != null) {
      return Icon(
        IconUtils.getIconData(fallbackIcon!),
        size: size * 0.7,
        color: fallbackColor ?? Colors.grey,
      );
    }

    IconData iconData = Icons.account_balance_wallet;
    Color color = Colors.grey;

    if (label.contains('tarjeta') || label.contains('visa') || label.contains('master')) {
      iconData = Icons.credit_card;
      color = Theme.of(context).colorScheme.primary;
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
