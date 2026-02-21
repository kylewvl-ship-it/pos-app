import 'package:flutter/foundation.dart';
import '../models/stock_item.dart';
import '../services/database_service.dart';

class StockProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  List<StockItem> _items = [];
  bool _isLoading = false;

  List<StockItem> get items => _items;
  bool get isLoading => _isLoading;

  // Count of items considered "running low". Threshold is 5 by default.
  int get lowStockCount => _items.where((i) => i.quantity <= 5).length;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _db.getAllStockItems();
    } catch (e) {
      debugPrint('Error loading stock items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(StockItem item) async {
    try {
      final newItem = await _db.createStockItem(item);
      _items.add(newItem);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding stock item: $e');
      rethrow;
    }
  }

  Future<void> updateItem(StockItem item) async {
    try {
      await _db.updateStockItem(item);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = item;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating stock item: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _db.deleteStockItem(id);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting stock item: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(int id, int newQuantity) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final item = _items[idx];
    final updatedItem = item.copyWith(quantity: newQuantity);
    await updateItem(updatedItem);
  }
}
