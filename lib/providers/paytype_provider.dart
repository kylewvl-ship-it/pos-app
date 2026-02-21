import 'package:flutter/foundation.dart';
import '../models/pay_type.dart';
import '../services/database_service.dart';

class PayTypeProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  List<PayType> _items = [];

  List<PayType> get items => List.unmodifiable(_items);

  Future<void> loadPayTypes() async {
    try {
      _items = await _db.getAllPayTypes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading pay types: $e');
    }
  }

  Future<void> addPayType(String name) async {
    final p = PayType(name: name);
    final saved = await _db.createPayType(p);
    _items.add(saved);
    notifyListeners();
  }

  Future<void> updatePayType(PayType p) async {
    await _db.updatePayType(p);
    final idx = _items.indexWhere((e) => e.id == p.id);
    if (idx != -1) {
      _items[idx] = p;
      notifyListeners();
    }
  }

  Future<void> deletePayType(int id) async {
    await _db.deletePayType(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
