import 'package:flutter/material.dart';
import '../../utils/icon_utils.dart';

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
            const Text('Logo Identificatorio:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => IconUtils.showUnifiedIconPicker(
                context: context,
                selectedValue: selectedLogo,
                isSelectedValueAsset: true,
                onSelected: (val, isAsset) => onSelect(val),
              ),
              icon: const Icon(Icons.grid_view, size: 16, color: Colors.teal),
              label: const Text(
                'Galería',
                style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.teal.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (selectedLogo != null && selectedLogo!.startsWith('http'))
                _logoItem(selectedLogo, true, () => onSelect(null), isUrl: true),
              _logoItem(null, selectedLogo == null, () => onSelect(null), isAuto: true),
              ...IconUtils.getAllAssetLogos().take(10).map((logoName) => _logoItem(logoName, selectedLogo == logoName, () => onSelect(logoName))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoItem(String? logo, bool isSelected, VoidCallback onTap, {bool isAuto = false, bool isUrl = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300, width: 2),
        ),
        child: Center(
          child: isAuto
              ? const Icon(Icons.auto_awesome, color: Colors.grey)
              : isUrl
                  ? ClipOval(child: Image.network(logo!, width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.public, color: Colors.grey)))
                  : ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          'assets/logos/$logo', 
                          width: 40, 
                          height: 40, 
                          fit: BoxFit.contain, 
                          errorBuilder: (c, e, s) => const Icon(Icons.business, color: Colors.grey),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
