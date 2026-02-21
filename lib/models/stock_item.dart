class StockItem {
  final int? id;
  final String name;
  final int quantity;
  final double price;
  final String unit;
  final String category;

  StockItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'category': category,
    };
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unit: map['unit'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String,
    );
  }

  StockItem copyWith({
    int? id,
    String? name,
    int? quantity,
    String? unit,
    double? price,
    String? category,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      category: category ?? this.category,
    );
  }
}
