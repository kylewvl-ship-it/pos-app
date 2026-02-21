import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/paytype_provider.dart';
import 'menu_management_screen.dart';
import 'manage_paytypes_screen.dart';
import 'transactions_screen.dart';
import 'stock_screen.dart';
import 'sales_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadItems();
      context.read<SalesProvider>().loadSalesHistory();
      context.read<MenuProvider>().loadMenu();
      context.read<PayTypeProvider>().loadPayTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();
    final salesProvider = context.watch<SalesProvider>();

    final totalStock = stockProvider.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    final totalSales = salesProvider.salesHistory.length;
    final totalRevenue = salesProvider.salesHistory.fold<double>(
      0.0,
      (sum, sale) => sum + sale.total,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column with buttons
            Container(
              width: 260,
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ActionButton(
                    label: stockProvider.lowStockCount > 0
                        ? 'Manage Stock (${stockProvider.lowStockCount} low)'
                        : 'Manage Stock',
                    icon: Icons.inventory,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StockScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: 'New Sale',
                    icon: Icons.point_of_sale,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SalesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: 'Manage Menu',
                    icon: Icons.restaurant_menu,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MenuManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: 'Manage Paytypes',
                    icon: Icons.payment,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManagePayTypesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    label: 'Transactions',
                    icon: Icons.receipt_long,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Right content area (empty)
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
