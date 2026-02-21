import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/paytype_provider.dart';
import '../../models/pay_type.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  PayType? _selectedPayType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pt = context.read<PayTypeProvider>();
      if (pt.items.isEmpty) pt.loadPayTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final salesProvider = context.watch<SalesProvider>();
    final payTypeProvider = context.watch<PayTypeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (salesProvider.cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => salesProvider.clearCart(),
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: Column(
        children: [
          // Cart Items
          Expanded(
            child: salesProvider.cartItems.isEmpty
                ? const Center(
                    child: Text('Cart is empty. Add items to start a sale.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: salesProvider.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = salesProvider.cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                child: Text(item.stockItemName.isNotEmpty ? item.stockItemName[0].toUpperCase() : '?'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.stockItemName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('\$${item.price.toStringAsFixed(2)} × ${item.quantity}', style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => salesProvider.updateCartItemQuantity(index, item.quantity - 1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => salesProvider.updateCartItemQuantity(index, item.quantity + 1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.redAccent,
                                        onPressed: () => salesProvider.removeFromCart(index),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Total and Checkout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('\$${salesProvider.cartTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (payTypeProvider.items.isNotEmpty) ...[
                      DropdownButtonFormField<PayType>(
                        decoration: const InputDecoration(labelText: 'Payment Type'),
                        value: _selectedPayType ?? (payTypeProvider.items.isNotEmpty ? payTypeProvider.items.first : null),
                        items: payTypeProvider.items.map((pt) => DropdownMenuItem(value: pt, child: Text(pt.name))).toList(),
                        onChanged: (v) => setState(() => _selectedPayType = v),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 18), elevation: 0),
                        onPressed: salesProvider.cartItems.isEmpty
                            ? null
                            : () async {
                                await salesProvider.completeSale(paymentType: _selectedPayType?.name ?? (payTypeProvider.items.isNotEmpty ? payTypeProvider.items.first.name : null));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed successfully!'), backgroundColor: Colors.green));
                                  Navigator.pop(context);
                                }
                              },
                        child: const Text('Complete Sale'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context, menuProvider, salesProvider),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showAddItemDialog(
    BuildContext context,
    MenuProvider menuProvider,
    SalesProvider salesProvider,
  ) {
    if (menuProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No menu items available. Add menu items first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        menuProvider: menuProvider,
        salesProvider: salesProvider,
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final MenuProvider menuProvider;
  final SalesProvider salesProvider;

  const _AddItemDialog({
    required this.menuProvider,
    required this.salesProvider,
  });

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  int? selectedItemId;
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final selectedItem = selectedItemId != null
      ? widget.menuProvider.items.firstWhere((item) => item.id == selectedItemId)
      : null;

    return AlertDialog(
      title: const Text('Add Item to Cart'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Select Item'),
            initialValue: selectedItemId,
            items: widget.menuProvider.items.map((item) {
              return DropdownMenuItem(
                value: item.id,
                child: Text('${item.name} - \$${item.amount.toStringAsFixed(2)}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedItemId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Quantity:'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
              ),
              Text(
                quantity.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => quantity++),
              ),
            ],
          ),
          if (selectedItem != null) ...[
            const SizedBox(height: 16),
            Text(
              'Total: \$${(selectedItem.amount * quantity).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedItem != null
              ? () {
                  widget.salesProvider.addMenuItemToCart(selectedItem, quantity);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}
