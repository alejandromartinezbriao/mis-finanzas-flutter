import 'package:flutter/material.dart';
import '../utils/icon_utils.dart';

class BrandIcon extends StatelessWidget {
  final String name;
  final String? manualLogo;
  final String? fallbackIcon;
  final Color? fallbackColor;
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
    final design = _getInstitutionDesign(label);

    Widget content;
    Color iconColor = design.color;
    
    // --- LÓGICA DE PRIORIDAD DE LOGO ---
    
    if (manualLogo != null) {
      if (manualLogo!.startsWith('http')) {
        // 1. Logo por URL (Premium/Manual)
        content = Image.network(
          manualLogo!,
          width: size * 0.8, height: size * 0.8, fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildDesignContent(design, iconColor),
        );
      } else if (manualLogo!.endsWith('.png')) {
        // 2. Logo por Asset local (Protegido o genérico)
        content = Image.asset(
          'assets/logos/$manualLogo',
          width: size * 0.8, height: size * 0.8, fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildDesignContent(design, iconColor),
        );
      } else {
        // 3. Logo por Nombre de Icono Material (Personalizado por el usuario)
        content = Icon(
          IconUtils.getIconData(manualLogo),
          size: size * 0.6,
          color: iconColor,
        );
      }
    } else {
      // 4. Si no hay logo manual, ver si es una institución reconocida
      if (!design.isGeneric) {
        content = _buildDesignContent(design, iconColor);
      } else if (fallbackIcon != null) {
        // 5. Fallback a icono de categoría
        content = Icon(
          IconUtils.getIconData(fallbackIcon!),
          size: size * 0.6,
          color: iconColor,
        );
      } else {
        // 6. Diseño genérico por defecto
        content = _buildDesignContent(design, iconColor);
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withOpacity(0.15),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Center(child: content),
    );
  }

  Widget _buildDesignContent(_BrandDesign design, Color color) {
    if (design.icon != null) {
      return Icon(design.icon, size: size * 0.6, color: color);
    }
    return Text(
      design.initials ?? '',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: size * 0.4,
        letterSpacing: -0.5,
      ),
    );
  }

  _BrandDesign _getInstitutionDesign(String label) {
    if (label.contains('santander')) return _BrandDesign(color: const Color(0xFFEC0000), initials: 'SA');
    if (label.contains('itau') || label.contains('itaú')) return _BrandDesign(color: const Color(0xFFFF7900), initials: 'IT');
    if (label.contains('bbva')) return _BrandDesign(color: const Color(0xFF004481), initials: 'BB');
    if (label.contains('scotia')) return _BrandDesign(color: const Color(0xFFED1C24), initials: 'SC');
    if (label.contains('republica') || label.contains('brou')) return _BrandDesign(color: const Color(0xFF00549A), initials: 'BR');
    if (label.contains('oca')) return _BrandDesign(color: const Color(0xFF0033A0), initials: 'OC');
    if (label.contains('prex')) return _BrandDesign(color: const Color(0xFF00B5E2), initials: 'PR');
    if (label.contains('midinero') || label.contains('dinero')) return _BrandDesign(color: const Color(0xFF00A9E0), initials: 'MD');
    if (label.contains('cabal')) return _BrandDesign(color: const Color(0xFF003876), initials: 'CA');
    if (label.contains('srpffaa') || label.contains('militar')) return _BrandDesign(color: const Color(0xFF2E7D32), initials: 'SR');

    if (label.contains('ute') || label.contains('luz')) return _BrandDesign(color: const Color(0xFFFFD600), icon: Icons.bolt);
    if (label.contains('ose') || label.contains('agua')) return _BrandDesign(color: const Color(0xFF0072CE), icon: Icons.water_drop);
    if (label.contains('antel') || label.contains('teléfono')) return _BrandDesign(color: const Color(0xFF8BC34A), initials: 'AN');
    if (label.contains('imm') || label.contains('intendencia')) return _BrandDesign(color: const Color(0xFF009688), initials: 'IM');
    if (label.contains('ces') || label.contains('alarma')) return _BrandDesign(color: const Color(0xFFD32F2F), icon: Icons.security);

    if (label.contains('alquiler') || label.contains('casa')) return _BrandDesign(color: const Color(0xFF5D4037), icon: Icons.home);
    if (label.contains('comunes')) return _BrandDesign(color: const Color(0xFF455A64), icon: Icons.apartment);
    if (label.contains('tarjeta') || label.contains('visa') || label.contains('master')) return _BrandDesign(color: Colors.blueGrey, icon: Icons.credit_card);

    return _BrandDesign(color: fallbackColor ?? Colors.blueGrey, icon: null, isGeneric: true);
  }
}

class _BrandDesign {
  final Color color;
  final String? initials;
  final IconData? icon;
  final bool isGeneric;
  _BrandDesign({required this.color, this.initials, this.icon, this.isGeneric = false});
}
