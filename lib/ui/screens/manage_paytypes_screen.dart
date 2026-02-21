import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/paytype_provider.dart';
import '../../models/pay_type.dart';

class ManagePayTypesScreen extends StatelessWidget {
  const ManagePayTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PayTypeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Pay Types')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.items.length,
        itemBuilder: (context, i) {
          final p = provider.items[i];
          return Card(
            child: ListTile(
              title: Text(p.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEdit(context, p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () => provider.deletePayType(p.id!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Add PayType'),
      ),
    );
  }

  void _showAdd(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Pay Type'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isEmpty) return;
            final provider = context.read<PayTypeProvider>();
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await provider.addPayType(name);
              navigator.pop();
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text('Failed to add pay type: $e')));
            }
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context, PayType p) {
    final ctrl = TextEditingController(text: p.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Pay Type'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isEmpty) return;
            final provider = context.read<PayTypeProvider>();
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            try {
              final updated = p.copyWith(name: name);
              await provider.updatePayType(updated);
              navigator.pop();
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text('Failed to save pay type: $e')));
            }
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}
