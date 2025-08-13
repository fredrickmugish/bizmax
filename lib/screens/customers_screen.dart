import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/customers_provider.dart';
import '../providers/records_provider.dart';
import 'package:flutter/foundation.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CustomersProvider>().loadCustomers());
  }

  void _showAddOrEditCustomerDialog({Customer? customer}) {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null
            ? 'Ongeza Mteja'
            : (customer.id == 0 ? 'Hifadhi' : 'Hariri Mteja')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customer != null && customer.id == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: const [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(child: Text('Weka namba ya simu', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jina la Mteja',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Namba ya Simu',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jina na namba ya simu haviwezi kuwa tupu'), backgroundColor: Colors.red),
                );
                return;
              }
              final phoneRegExp = RegExp(r'^(\+?\d{10,15})$');
              if (!phoneRegExp.hasMatch(phone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Weka namba ya simu halali (tarakimu 10 hadi 15)'), backgroundColor: Colors.red),
                );
                return;
              }
              final provider = context.read<CustomersProvider>();
              if (customer == null || customer.id == '0') {
                await provider.addCustomer(name, phone);
              } else {
                await provider.updateCustomer(customer.id!, name, phone);
              }
              // Refresh both providers to update the UI correctly
              await provider.loadCustomers();
              await context.read<RecordsProvider>().loadRecords();
              Navigator.pop(context);
            },
            child: Text(customer == null
                ? 'Ongeza'
                : 'Hifadhi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wateja'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tafuta mteja',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: Consumer2<CustomersProvider, RecordsProvider>(
              builder: (context, customersProvider, recordsProvider, _) {
                if (customersProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Get customers from /customers endpoint
                final customers = customersProvider.customers;
                // Get unique customer names from sales
                final salesCustomerNames = recordsProvider.uniqueCustomers;
                // Get unique supplier names from purchases
                final supplierNames = recordsProvider.allRecords
                    .where((record) => record.type == 'purchase' && record.supplierName != null && record.supplierName!.isNotEmpty)
                    .map((record) => record.supplierName!)
                    .toSet();

                // Merge all unique names
                final allNames = {...salesCustomerNames, ...supplierNames};

                // Merge: create a map by name for fast lookup
                final Map<String, Customer> merged = {
                  for (var c in customers) c.name: c
                };

                // Add unregistered customers (if not already in /customers)
                for (final name in allNames) {
                  if (!merged.containsKey(name)) {
                    merged[name] = Customer(id: '0', name: name, phone: '');
                  }
                }
                // Convert to list and sort alphabetically
                final allCustomers = merged.values.toList()
                  ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                // Filter by search
                final filtered = _searchQuery.isEmpty
                    ? allCustomers
                    : allCustomers.where((c) =>
                        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        c.phone.contains(_searchQuery)).toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No customers found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return ListTile(
                      leading: const Icon(Icons.person, color: Colors.indigo),
                      title: Row(
                        children: [
                          Expanded(child: Text(customer.name)),
                          if (customer.phone.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                customer.phone,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => _showAddOrEditCustomerDialog(customer: customer),
                      onLongPress: customer.id != '0'
                          ? () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Customer'),
                                  content: Text('Are you sure you want to delete \\${customer.name}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await context.read<CustomersProvider>().deleteCustomer(customer.id!);
                              }
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditCustomerDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
        tooltip: 'Add Customer',
      ),
    );
  }
} 