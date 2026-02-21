import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/stock_item.dart';
import '../../providers/stock_provider.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        actions: [
          if (stockProvider.lowStockCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Chip(
                backgroundColor: Colors.red.shade700,
                label: Text(
                  'Running low: ${stockProvider.lowStockCount}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: stockProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : stockProvider.items.isEmpty
              ? const Center(
                  child: Text('No stock items. Add your first item!'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stockProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = stockProvider.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(item.name[0].toUpperCase()),
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          'Category: ${item.category} | Qty: ${item.quantity}',
                        ),
                        trailing: Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _showEditDialog(context, item),
                        onLongPress: () => _showDeleteDialog(context, item),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stock Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit (kg, ml, etc.)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final category = categoryController.text.trim();
              final unit = unitController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0.0;
              if (name.isNotEmpty && category.isNotEmpty && unit.isNotEmpty && quantity > 0 && price > 0) {
                final item = StockItem(
                  name: name,
                  category: category,
                  unit: unit,
                  quantity: quantity,
                  price: price,
                );

                await context.read<StockProvider>().addItem(item);
                Navigator.of(context, rootNavigator: true).pop(); // Always close dialog
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, StockItem item) {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.price.toString());
    final categoryController = TextEditingController(text: item.category);
    final unitController = TextEditingController(text: item.unit);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Stock Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit (kg, ml, etc.)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (item.id != null)
            ElevatedButton(
              onPressed: () async {
                final id = item.id!;
                await context.read<StockProvider>().deleteItem(id);
                if (context.mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final category = categoryController.text.trim();
              final unit = unitController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0.0;
              if (name.isNotEmpty && category.isNotEmpty && unit.isNotEmpty && quantity > 0 && price > 0) {
                final updated = item.copyWith(
                  name: name,
                  category: category,
                  unit: unit,
                  quantity: quantity,
                  price: price,
                );
                await context.read<StockProvider>().updateItem(updated);
                Navigator.of(context).pop(); // Close the dialog
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, StockItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<StockProvider>().deleteItem(item.id!);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
