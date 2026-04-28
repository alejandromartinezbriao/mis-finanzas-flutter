class CategoryModel {
  final String id;
  final String name;
  final String icon; // Store the icon name as a string (e.g., 'shopping_cart')
  final int color; // Store color as an ARGB integer
  final String type; // 'EXPENSE' or 'INCOME'

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? 'category',
      color: data['color'] ?? 0xFF9E9E9E, // Default grey
      type: data['type'] ?? 'EXPENSE',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
    };
  }
}
