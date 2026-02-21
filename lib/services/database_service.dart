import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/stock_item.dart';
import '../models/menu_item.dart';
import '../models/sale.dart';
import '../models/pay_type.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos.db');
    return _database!;
  }

  // Menu Item CRUD operations
  Future<MenuItemModel> createMenuItem(MenuItemModel item) async {
    final db = await database;
    final id = await db.insert('menu_items', {
      'name': item.name,
      'amount': item.amount,
      'cost': item.cost,
      'stockItemId': item.stockItemId,
      'recipe': jsonEncode(item.recipe),
    });
    debugPrint('DatabaseService.createMenuItem: inserted id=$id for ${item.name}');
    return MenuItemModel(
      id: id,
      name: item.name,
      amount: item.amount,
      cost: item.cost,
      stockItemId: item.stockItemId,
      recipe: item.recipe,
    );
  }

  Future<List<MenuItemModel>> getAllMenuItems() async {
    final db = await database;
    final result = await db.query('menu_items', orderBy: 'name ASC');
    return result.map((map) {
      final recipe = map['recipe'] != null ? jsonDecode(map['recipe'] as String) : [];
      return MenuItemModel.fromMap({
        'id': map['id'] as int,
        'name': map['name'] as String,
        'amount': (map['amount'] as num).toDouble(),
        'cost': (map['cost'] as num).toDouble(),
        'stockItemId': map['stockItemId'] as int?,
        'recipe': recipe,
      });
    }).toList();
  }

  Future<int> updateMenuItem(MenuItemModel item) async {
    final db = await database;
    return await db.update(
      'menu_items',
      {
        'name': item.name,
        'amount': item.amount,
        'cost': item.cost,
        'stockItemId': item.stockItemId,
        'recipe': jsonEncode(item.recipe),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE sales ADD COLUMN invoice_number TEXT');
          } catch (e) {
            debugPrint('onUpgrade: invoice_number column may already exist: $e');
          }
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE sales ADD COLUMN payment_type TEXT');
          } catch (e) {
            debugPrint('onUpgrade: payment_type column may already exist: $e');
          }
          // create pay_types table for older databases
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS pay_types (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL
              )
            ''');
          } catch (e) {
            debugPrint('onUpgrade: creating pay_types failed: $e');
          }
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stock_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT,
        items TEXT NOT NULL,
        total REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        cost REAL NOT NULL,
        stockItemId INTEGER,
        recipe TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pay_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
  }

  // PayType CRUD
  Future<PayType> createPayType(PayType p) async {
    final db = await database;
    try {
      final id = await db.insert('pay_types', {'name': p.name});
      return PayType(id: id, name: p.name);
    } catch (e) {
      // If table doesn't exist (older DB), create it and retry
      if (e.toString().contains('no such table')) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pay_types (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        final id = await db.insert('pay_types', {'name': p.name});
        return PayType(id: id, name: p.name);
      }
      rethrow;
    }
  }

  Future<List<PayType>> getAllPayTypes() async {
    final db = await database;
    try {
      final result = await db.query('pay_types', orderBy: 'name ASC');
      return result.map((m) => PayType.fromMap(m)).toList();
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pay_types (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        return [];
      }
      rethrow;
    }
  }

  Future<int> updatePayType(PayType p) async {
    final db = await database;
    return db.update('pay_types', {'name': p.name}, where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deletePayType(int id) async {
    final db = await database;
    return db.delete('pay_types', where: 'id = ?', whereArgs: [id]);
  }

  // Stock Item CRUD operations
  Future<StockItem> createStockItem(StockItem item) async {
    final db = await database;
    final id = await db.insert('stock_items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<List<StockItem>> getAllStockItems() async {
    final db = await database;
    final result = await db.query('stock_items', orderBy: 'name ASC');
    return result.map((map) => StockItem.fromMap(map)).toList();
  }

  Future<StockItem?> getStockItem(int id) async {
    final db = await database;
    final maps = await db.query(
      'stock_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return StockItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateStockItem(StockItem item) async {
    final db = await database;
    return db.update(
      'stock_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteStockItem(int id) async {
    final db = await database;
    return await db.delete(
      'stock_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sales CRUD operations
  Future<Sale> createSale(Sale sale) async {
    final db = await database;
    final saleMap = {
      'invoice_number': sale.invoiceNumber,
      'items': jsonEncode(sale.items.map((item) => item.toMap()).toList()),
      'total': sale.total,
      'payment_type': sale.paymentType,
      'timestamp': sale.timestamp.toIso8601String(),
    };
    final id = await db.insert('sales', saleMap);
    return Sale(
      id: id,
      invoiceNumber: sale.invoiceNumber,
      items: sale.items,
      total: sale.total,
      paymentType: sale.paymentType,
      timestamp: sale.timestamp,
    );
  }

  Future<List<Sale>> getAllSales() async {
    final db = await database;
    final result = await db.query('sales', orderBy: 'timestamp DESC');
    return result.map((map) {
      final itemsJson = jsonDecode(map['items'] as String) as List;
      final items = itemsJson
          .map((item) => SaleItem.fromMap(item as Map<String, dynamic>))
          .toList();
      return Sale(
        id: map['id'] as int,
        invoiceNumber: map['invoice_number'] as String? ?? 'INV${map['id']}',
        items: items,
        total: (map['total'] as num).toDouble(),
        paymentType: map['payment_type'] as String?,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
    }).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
