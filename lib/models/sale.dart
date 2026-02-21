import 'dart:convert';

class SaleItem {
  final int? stockItemId;
  final String stockItemName;
  final int quantity;
  final double price;

  SaleItem({
    this.stockItemId,
    required this.stockItemName,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'stockItemId': stockItemId,
      'stockItemName': stockItemName,
      'quantity': quantity,
      'price': price,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      stockItemId: map['stockItemId'] as int?,
      stockItemName: map['stockItemName'] as String,
      quantity: (map['quantity'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
    );
  }
}

class Sale {
  final int? id;
  final String invoiceNumber;
  final List<SaleItem> items;
  final double total;
  final String? paymentType;
  final DateTime timestamp;

  Sale({
    this.id,
    required this.invoiceNumber,
    required this.items,
    required this.total,
    this.paymentType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'items': jsonEncode(items.map((item) => item.toMap()).toList()),
      'total': total,
      'payment_type': paymentType,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      invoiceNumber: (map['invoice_number'] ?? map['invoiceNumber'] ?? '') as String,
      items: () {
        final raw = map['items'];
        if (raw is String) {
          try {
            final decoded = jsonDecode(raw) as List;
            return decoded.map((item) => SaleItem.fromMap(item as Map<String, dynamic>)).toList();
          } catch (_) {
            return <SaleItem>[];
          }
        } else if (raw is List) {
          return raw.map((item) => SaleItem.fromMap(item as Map<String, dynamic>)).toList();
        }
        return <SaleItem>[];
      }(),
      total: (map['total'] as num).toDouble(),
      paymentType: (map['payment_type'] ?? map['paymentType']) as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
