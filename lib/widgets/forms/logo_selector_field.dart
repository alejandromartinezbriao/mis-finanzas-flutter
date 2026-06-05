import 'package:flutter/material.dart';
import '../../utils/icon_utils.dart';
import '../brand_icon.dart';

class LogoSelectorField extends StatelessWidget {
  final String? selectedLogo;
  final Function(String?) onSelect;
  final String currentName;

  const LogoSelectorField({
    super.key,
    required this.selectedLogo,
    required this.onSelect,
    required this.currentName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Personalizar Identidad:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => IconUtils.showUnifiedIconPicker(
                context: context,
                selectedValue: selectedLogo,
                isSelectedValueAsset: selectedLogo?.endsWith('.png') ?? false,
                onSelected: (val, isAsset) => onSelect(val),
              ),
              icon: const Icon(Icons.grid_view, size: 16, color: Colors.teal),
              label: const Text('Galería', style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.teal.withOpacity(0.05),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // --- PREVISUALIZACIÓN Y ACCESO RÁPIDO ---
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              // 1. Opción Automática (Reset)
              _item(
                child: const Icon(Icons.auto_awesome, color: Colors.grey, size: 24),
                label: 'Auto',
                isSelected: selectedLogo == null,
                onTap: () => onSelect(null),
              ),

              // 2. Logo Seleccionado (Si no está en la lista rápida)
              if (selectedLogo != null && !IconUtils.getAllAssetLogos().contains(selectedLogo))
                _item(
                  child: BrandIcon(name: currentName, manualLogo: selectedLogo, size: 36),
                  label: 'Actual',
                  isSelected: true,
                  onTap: () {},
                ),

              // 3. Logos Rápidos (Assets genéricos)
              ...IconUtils.getAllAssetLogos().map((logo) => _item(
                child: Image.asset('assets/logos/$logo', width: 30, height: 30, fit: BoxFit.contain),
                label: logo.split('.').first,
                isSelected: selectedLogo == logo,
                onTap: () => onSelect(logo),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _item({required Widget child, required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.teal.withOpacity(0.2) : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.teal : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 4)] : null,
              ),
              child: Center(child: child),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 8, color: isSelected ? Colors.teal : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
