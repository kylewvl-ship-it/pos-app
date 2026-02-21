import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../services/database_service.dart';

class MenuProvider extends ChangeNotifier {
  final List<MenuItemModel> _items = [];
  int _nextId = 1;
  final DatabaseService _db = DatabaseService.instance;

  List<MenuItemModel> get items => List.unmodifiable(_items);

  void loadMenu() {
    () async {
      try {
        final list = await _db.getAllMenuItems();
        _items.clear();
        _items.addAll(list);
      } catch (e) {
        debugPrint('Error loading menu items: $e');
      }
      notifyListeners();
    }();
  }

  Future<void> addMenuItem(String name, double amount, double cost, int? stockItemId, List<Map<String, dynamic>> recipe) async {
    try {
      final item = MenuItemModel(
        id: 0,
        name: name,
        amount: amount,
        cost: cost,
        stockItemId: stockItemId,
        recipe: recipe,
      );
      final saved = await _db.createMenuItem(item);
      debugPrint('MenuProvider.addMenuItem: saved menu item id=${saved.id} name=${saved.name} cost=${saved.cost}');
      _items.add(saved);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving menu item: $e');
      rethrow;
    }
  }

  Future<void> updateMenuItem(int id, {String? name, double? amount, double? cost, int? stockItemId, List<Map<String, dynamic>>? recipe}) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final item = _items[idx];
    final updated = item.copyWith(
      name: name,
      amount: amount,
      cost: cost,
      stockItemId: stockItemId,
      recipe: recipe,
    );
    _items[idx] = updated;
    notifyListeners();
    try {
      await _db.updateMenuItem(updated);
    } catch (e) {
      debugPrint('Error updating menu item in DB: $e');
      rethrow;
    }
  }

  void removeMenuItem(int id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
