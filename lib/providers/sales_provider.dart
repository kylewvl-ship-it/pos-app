import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../models/stock_item.dart';
import '../models/menu_item.dart';
import '../services/database_service.dart';

class SalesProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final List<SaleItem> _cartItems = [];
  List<Sale> _salesHistory = [];
  bool _isLoading = false;

  List<SaleItem> get cartItems => _cartItems;
  List<Sale> get salesHistory => _salesHistory;
  bool get isLoading => _isLoading;

  double get cartTotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.total);
  }

  void addToCart(StockItem stockItem, int quantity) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.stockItemId != null && item.stockItemId == stockItem.id,
    );

    if (existingIndex != -1) {
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] = SaleItem(
        stockItemId: existing.stockItemId,
        stockItemName: existing.stockItemName,
        quantity: existing.quantity + quantity,
        price: existing.price,
      );
    } else {
      _cartItems.add(SaleItem(
        stockItemId: stockItem.id,
        stockItemName: stockItem.name,
        quantity: quantity,
        price: stockItem.price,
      ));
    }
    notifyListeners();
  }

  void addMenuItemToCart(MenuItemModel menuItem, int quantity) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.stockItemName == menuItem.name,
    );

    if (existingIndex != -1) {
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] = SaleItem(
        stockItemId: existing.stockItemId,
        stockItemName: existing.stockItemName,
        quantity: existing.quantity + quantity,
        price: existing.price,
      );
    } else {
      _cartItems.add(SaleItem(
        stockItemId: menuItem.stockItemId,
        stockItemName: menuItem.name,
        quantity: quantity,
        price: menuItem.amount,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  void updateCartItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(index);
    } else {
      final item = _cartItems[index];
      _cartItems[index] = SaleItem(
        stockItemName: item.stockItemName,
        quantity: newQuantity,
        price: item.price,
      );
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<void> completeSale({String? paymentType}) async {
    if (_cartItems.isEmpty) return;

    try {
      // generate invoice number
      final invoice = 'INV${DateTime.now().millisecondsSinceEpoch}';
      final sale = Sale(
        invoiceNumber: invoice,
        items: List.from(_cartItems),
        total: cartTotal,
        paymentType: paymentType,
        timestamp: DateTime.now(),
      );

      await _db.createSale(sale);
      _cartItems.clear();
      await loadSalesHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing sale: $e');
      rethrow;
    }
  }

  Future<void> loadSalesHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _salesHistory = await _db.getAllSales();
    } catch (e) {
      debugPrint('Error loading sales history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
