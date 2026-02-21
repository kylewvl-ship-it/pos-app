import 'dart:convert';

class MenuItemModel {
  final int id;
  final String name;
  final double amount;
  final double cost;
  final int? stockItemId; // optional link to a StockItem
  final List<Map<String, dynamic>> recipe; // List of {id, name, quantity}

  MenuItemModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.cost,
    this.stockItemId,
    this.recipe = const [],
  });

  MenuItemModel copyWith({
    int? id,
    String? name,
    double? amount,
    double? cost,
    int? stockItemId,
    List<Map<String, dynamic>>? recipe,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      cost: cost ?? this.cost,
      stockItemId: stockItemId ?? this.stockItemId,
      recipe: recipe ?? this.recipe,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'cost': cost,
      'stockItemId': stockItemId,
      'recipe': recipe.isNotEmpty ? recipe.map((e) => e).toList() : [],
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'] as int,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      stockItemId: map['stockItemId'] as int?,
      recipe: () {
        final r = map['recipe'];
        if (r == null) return <Map<String, dynamic>>[];
        if (r is String) {
          try {
            final decoded = jsonDecode(r);
            return List<Map<String, dynamic>>.from(decoded as List);
          } catch (_) {
            return <Map<String, dynamic>>[];
          }
        }
        return List<Map<String, dynamic>>.from(r as List);
      }(),
    );
  }
}
