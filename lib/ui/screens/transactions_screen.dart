import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_provider.dart';
import '../../models/sale.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: salesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: salesProvider.salesHistory.length,
              itemBuilder: (context, index) {
                final sale = salesProvider.salesHistory[index];
                return Card(
                  child: ListTile(
                    title: Text(sale.invoiceNumber),
                    subtitle: Text('${sale.items.length} items • \$${sale.total.toStringAsFixed(2)}'),
                    trailing: Text('${sale.timestamp.toLocal()}'),
                    onTap: () => _showSaleDetail(context, sale),
                  ),
                );
              },
            ),
    );
  }

  void _showSaleDetail(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice: ${sale.invoiceNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${sale.timestamp.toLocal()}'),
              const SizedBox(height: 8),
              ...sale.items.map((it) => ListTile(
                    title: Text(it.stockItemName),
                    subtitle: Text('${it.quantity} × \$${it.price.toStringAsFixed(2)}'),
                    trailing: Text('\$${it.total.toStringAsFixed(2)}'),
                  )),
              const Divider(),
              Text('Total: \$${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
