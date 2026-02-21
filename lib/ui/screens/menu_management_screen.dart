import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/stock_provider.dart';
import '../../models/menu_item.dart';

class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final stockProvider = context.watch<StockProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: menuProvider.items.length,
        itemBuilder: (context, index) {
          final item = menuProvider.items[index];
          final linkedStock = item.stockItemId != null
              ? stockProvider.items.firstWhere(
                  (s) => s.id == item.stockItemId,
                  orElse: () => null as dynamic,
                )
              : null;
          return Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text('Price: \$${item.amount.toStringAsFixed(2)} • Cost: \$${item.cost.toStringAsFixed(2)}' + (linkedStock != null ? ' • Stock: ${linkedStock.name}' : '')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context, item, stockProvider),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => menuProvider.removeMenuItem(item.id),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, stockProvider),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, StockProvider stockProvider) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    List<Map<String, dynamic>> recipeItems = [];
    double computedCost = 0.0;

    double computeCost() {
      double total = 0.0;
      for (final ri in recipeItems) {
        final sid = ri['id'] as int?;
        final qty = (ri['quantity'] as num?)?.toDouble() ?? 0.0;
        if (sid != null) {
          final stock = stockProvider.items.firstWhere((s) => s.id == sid, orElse: () => null as dynamic);
          if (stock != null) {
            total += (stock.price * qty);
          }
        }
      }
      return total;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Menu Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Recipe', style: TextStyle(fontWeight: FontWeight.bold)),
                ...recipeItems.map((item) => ListTile(
                      title: Text(item['name']),
                      subtitle: Text('Qty: ${item['quantity']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            recipeItems.remove(item);
                            computedCost = computeCost();
                          });
                        },
                      ),
                    )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cost of item:'),
                    Text('\$${computedCost.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Stock Item'),
                  onPressed: () async {
                    int? selectedStockId;
                    final qtyCtrl = TextEditingController();
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add Stock Item to Recipe'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<int?>(
                              decoration: const InputDecoration(labelText: 'Select Stock Item'),
                              value: selectedStockId,
                              items: [
                                ...stockProvider.items.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                              ],
                              onChanged: (v) => selectedStockId = v,
                            ),
                              TextField(
                                controller: qtyCtrl,
                                decoration: const InputDecoration(labelText: 'Quantity'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (selectedStockId != null && double.tryParse(qtyCtrl.text) != null) {
                                final stock = stockProvider.items.firstWhere((s) => s.id == selectedStockId);
                                setState(() {
                                  recipeItems.add({
                                    'id': stock.id,
                                    'name': stock.name,
                                      'quantity': double.parse(qtyCtrl.text),
                                  });
                                  computedCost = computeCost();
                                });
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final price = double.tryParse(priceCtrl.text) ?? 0.0;
                  if (name.isEmpty || price <= 0) return;
                  final cost = computedCost;
                  await context.read<MenuProvider>().addMenuItem(name, price, cost, null, recipeItems);
                  if (context.mounted) Navigator.pop(context);
                },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, MenuItemModel menuItem, StockProvider stockProvider) {
    final nameCtrl = TextEditingController(text: menuItem.name);
    final amountCtrl = TextEditingController(text: menuItem.amount.toString());
    // recipe items local copy so we can edit
    List<Map<String, dynamic>> recipeItems = menuItem.recipe.map((e) => Map<String, dynamic>.from(e)).toList();
    double computedCost = 0.0;

    double computeCost() {
      double total = 0.0;
      for (final ri in recipeItems) {
        final sid = ri['id'] as int?;
        final qty = (ri['quantity'] as num?)?.toDouble() ?? 0.0;
        if (sid != null) {
          final stock = stockProvider.items.firstWhere((s) => s.id == sid, orElse: () => null as dynamic);
          if (stock != null) total += (stock.price * qty);
        }
      }
      return total;
    }

    computedCost = computeCost();
    final costCtrl = TextEditingController(text: computedCost.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              // Cost is computed from recipe; show read-only
              TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Cost'), keyboardType: TextInputType.number, readOnly: true),
              const SizedBox(height: 12),
              const Text('Recipe', style: TextStyle(fontWeight: FontWeight.bold)),
              ...recipeItems.map((ri) => ListTile(
                    title: Text(ri['name']),
                    subtitle: Text('Qty: ${ri['quantity']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        recipeItems.remove(ri);
                        computedCost = computeCost();
                        costCtrl.text = computedCost.toStringAsFixed(2);
                      },
                    ),
                  )),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cost of item:'),
                  Text('\$${computedCost.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Stock Item'),
                onPressed: () async {
                  int? selectedId;
                  final qtyCtrl = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Add Stock Item to Recipe'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<int?>(
                            decoration: const InputDecoration(labelText: 'Select Stock Item'),
                            value: selectedId,
                            items: [
                              ...stockProvider.items.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                            ],
                            onChanged: (v) => selectedId = v,
                          ),
                          TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedId != null && double.tryParse(qtyCtrl.text) != null) {
                              final stock = stockProvider.items.firstWhere((s) => s.id == selectedId);
                              recipeItems.add({'id': stock.id, 'name': stock.name, 'quantity': double.parse(qtyCtrl.text)});
                              computedCost = computeCost();
                              costCtrl.text = computedCost.toStringAsFixed(2);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              final cost = computedCost;
              if (name.isEmpty) return;
              await context.read<MenuProvider>().updateMenuItem(menuItem.id, name: name, amount: amount, cost: cost, recipe: recipeItems);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

}
