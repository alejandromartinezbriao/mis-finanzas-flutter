import 'package:flutter/material.dart';

class IconUtils {
  // Lista unificada de nombres de íconos de Material
  static const List<String> _materialIconNames = [
    'shopping_cart', 'restaurant', 'directions_car', 'home',
    'flash_on', 'water_drop', 'phone_android', 'medical_services',
    'school', 'fitness_center', 'flight', 'movie',
    'payments', 'account_balance', 'redeem', 'pets',
    'work', 'sports_esports', 'stroller', 'cleaning_services',
    'subscriptions', 'coffee', 'local_bar', 'celebration',
    'savings', 'trending_up', 'favorite', 'security',
    'receipt_long', 'construction', 'local_gas_station', 'checkroom',
    'local_pharmacy', 'bakery_dining', 'icecream', 'vpn_key',
    'wifi', 'tv', 'local_laundry_service', 'face',
    'brush', 'computer', 'smartphone', 'directions_bus',
    'train', 'self_improvement', 'theater_comedy', 'piano',
    'videogame_asset', 'child_care', 'beach_access', 'directions_run',
    'shopping_bag', 'build', 'flag', 'category'
  ];

  // Lista unificada de logos personalizados en assets
  static const List<String> _assetLogos = [
    'banco-republica.png', 'itau.png', 'santander.png', 'bbva.png', 'scotiabank.png',
    'oca.png', 'oca-blue.png', 'prex.png', 'midinero.png', 'ahorros.png', 'cabal.png',
    'srpffaa.png', 'dinero.png', 'queen.png', 'bodyguard.png', 'alquiler.png',
    'ose.png', 'ute.png', 'imm.png', 'ces.png', 'gastos-comunes.png'
  ];

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
      case 'subscriptions': return Icons.subscriptions;
      case 'coffee': return Icons.coffee;
      case 'local_bar': return Icons.local_bar;
      case 'celebration': return Icons.celebration;
      case 'savings': return Icons.savings;
      case 'trending_up': return Icons.trending_up;
      case 'favorite': return Icons.favorite;
      case 'security': return Icons.security;
      case 'receipt_long': return Icons.receipt_long;
      case 'construction': return Icons.construction;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'checkroom': return Icons.checkroom;
      case 'local_pharmacy': return Icons.local_pharmacy;
      case 'bakery_dining': return Icons.bakery_dining;
      case 'icecream': return Icons.icecream;
      case 'vpn_key': return Icons.vpn_key;
      case 'wifi': return Icons.wifi;
      case 'tv': return Icons.tv;
      case 'local_laundry_service': return Icons.local_laundry_service;
      case 'face': return Icons.face;
      case 'brush': return Icons.brush;
      case 'computer': return Icons.computer;
      case 'smartphone': return Icons.smartphone;
      case 'directions_bus': return Icons.directions_bus;
      case 'train': return Icons.train;
      case 'self_improvement': return Icons.self_improvement;
      case 'theater_comedy': return Icons.theater_comedy;
      case 'piano': return Icons.piano;
      case 'videogame_asset': return Icons.videogame_asset;
      case 'child_care': return Icons.child_care;
      case 'beach_access': return Icons.beach_access;
      case 'directions_run': return Icons.directions_run;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'build': return Icons.build;
      default: return Icons.category;
    }
  }

  static List<String> getAllIconNames() => _materialIconNames;
  
  static List<String> getAllAssetLogos() => _assetLogos;

  /// Muestra una galería unificada que permite elegir entre íconos de Material y Logos de Assets
  static void showUnifiedIconPicker({
    required BuildContext context,
    required Function(String?, bool isAsset) onSelected,
    String? selectedValue,
    bool isSelectedValueAsset = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Icono o Logo'),
        content: SizedBox(
          width: double.maxFinite,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Iconos', icon: Icon(Icons.category)),
                    Tab(text: 'Logos', icon: Icon(Icons.business)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      // Grid de Iconos Material
                      GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: _materialIconNames.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _pickerItem(
                              context: context,
                              child: const Icon(Icons.auto_awesome, color: Colors.grey),
                              isSelected: selectedValue == null,
                              onTap: () {
                                onSelected(null, false);
                                Navigator.pop(context);
                              },
                            );
                          }
                          final name = _materialIconNames[index - 1];
                          return _pickerItem(
                            context: context,
                            child: Icon(getIconData(name), color: Colors.teal),
                            isSelected: !isSelectedValueAsset && selectedValue == name,
                            onTap: () {
                              onSelected(name, false);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                      // Grid de Logos Assets
                      GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: _assetLogos.length,
                        itemBuilder: (context, index) {
                          final logo = _assetLogos[index];
                          return _pickerItem(
                            context: context,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset('assets/logos/$logo', fit: BoxFit.contain),
                            ),
                            isSelected: isSelectedValueAsset && selectedValue == logo,
                            onTap: () {
                              onSelected(logo, true);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  static Widget _pickerItem({
    required BuildContext context,
    required Widget child,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}
