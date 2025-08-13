import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_item_card.dart';
import '../models/inventory_item.dart';
import '../utils/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../services/api_exception.dart';
import 'package:flutter/foundation.dart';

import 'package:cached_network_image/cached_network_image.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final userData = user != null && user['data'] != null ? user['data'] : user;
    final isSalesperson = userData != null && userData['role'] == 'salesperson';
    final salespersonName = userData != null ? userData['name'] : '';
    final isWeb = kIsWeb;
    final isSmallWeb = isWeb && MediaQuery.of(context).size.width < 840;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = 900.0;
    return Scaffold(
      appBar: AppBar(
        title: isSalesperson
            ? Text(context.watch<BusinessProvider>().businessName)
            : const Text('Hifadhi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !isWeb,
        leading: isSmallWeb
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              )
            : null,
        actions: [
          if (!isSalesperson)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addProduct).then((_) {
                  context.read<InventoryProvider>().loadInventory();
                });
              },
            ),
          if (isSalesperson)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _showLogoutConfirmationDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          if (isSalesperson)
            _buildWelcomeSection(salespersonName, isLoading: authProvider.isLoading),
          _buildSearchAndFilter(isWeb: isWeb),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return provider.filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: isWeb ? 80 : 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.searchQuery.isNotEmpty || provider.selectedCategory != 'All'
                                  ? 'Hakuna bidhaa zinazolingana na utafutaji'
                                  : 'Hakuna bidhaa zilizohifadhiwa',
                              style: TextStyle(
                                fontSize: isWeb ? 20 : 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (!isSalesperson)
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.addProduct).then((_) {
                                    context.read<InventoryProvider>().loadInventory();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text(
                                  'Ongeza Bidhaa',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => provider.loadInventory(),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: provider.filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = provider.filteredItems[index];
                            return InventoryItemCard(
                              product: item,
                              onTap: isSalesperson ? null : () => _showItemDetails(item),
                            );
                          },
                        ),
                      );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isSalesperson
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addProduct).then((_) {
                  context.read<InventoryProvider>().loadInventory();
                });
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildWelcomeSection(String? userName, {bool isLoading = false}) {
    if (isLoading) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Habari za Asubuhi';
    } else if (hour < 17) {
      greeting = 'Habari za Mchana';
    } else {
      greeting = 'Habari za Jioni';
    }
    final businessName = context.watch<BusinessProvider>().businessName;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, ${userName ?? 'Mtumiaji'}!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Karibu kwenye $businessName',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.business_center,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter({bool isWeb = false}) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tafuta bidhaa...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              context.read<InventoryProvider>().setSearchQuery(value);
            },
          ),
          SizedBox(height: isWeb ? 16 : 12),
          Consumer<InventoryProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: provider.categories.map((category) {
                    final isSelected = provider.selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          provider.setCategory(category);
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showItemDetails(InventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                  // Top row with edit and cancel icons
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Hariri',
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditProductDialog(item);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Futa',
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(item);
                      },
                    ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        tooltip: 'Funga',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  // Product image, name, category, kipimo in a row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: (item.productImage != null && item.productImage!.isNotEmpty)
                              ? _getCategoryColor(item.category)
                              : Colors.blue, // Use blue if no image
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: (item.productImage != null && item.productImage!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: item.productImage!,
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.inventory_2,
                                color: Colors.white,
                                size: 40,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                              const SizedBox(height: 6),
                        Text(
                     item.category ?? '', // This will now display an empty string
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                        ),

                            if (item.unitDimensions != null && item.unitDimensions!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Kipimo: ${item.unitDimensions}',
                                  style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                ),
                              ),
                          ],
                        ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                  // Details
                  _buildDetailRow('Idadi', '${item.currentStock} ${(item.unitDimensions != null && item.unitDimensions!.isNotEmpty) ? item.unitDimensions : 'bidhaa'}'),
                  _buildDetailRow('Bei ya Ununuzi', '@TSH '
                    + (item.buyingPrice % 1 == 0
                        ? item.buyingPrice.toStringAsFixed(0)
                        : item.buyingPrice.toStringAsFixed(2))),
                  if (item.wholesalePrice != null)
                    _buildDetailRow('Bei ya Jumla', '@TSH ${item.wholesalePrice!.toStringAsFixed(0)}'),
                  if (item.retailPrice != null)
                    _buildDetailRow('Bei ya Rejareja', '@TSH ${item.retailPrice!.toStringAsFixed(0)}'),
                  if (item.wholesalePrice == null && item.retailPrice == null)
                    _buildDetailRow('Bei ya Mauzo', '@TSH ${item.sellingPrice.toStringAsFixed(0)}'),
                  _buildDetailRow('Thamani ya Hifadhi', 'TSH ${(item.currentStock * item.buyingPrice).toStringAsFixed(0)}'),
                  _buildDetailRow('Kiwango cha Chini', '${item.minimumStock} ${(item.unitDimensions != null && item.unitDimensions!.isNotEmpty) ? item.unitDimensions : 'bidhaa'}'),
                  const SizedBox(height: 24),
                  // Action buttons
            
              ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditProductDialog(InventoryItem item) {
    Navigator.pushNamed(
      context,
      AppRoutes.addProduct,
      arguments: item,
    ).then((_) {
      context.read<InventoryProvider>().loadInventory();
    });
  }

  void _showStockUpdateDialog(InventoryItem item) {
    final controller = TextEditingController(text: item.currentStock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Badilisha Hifadhi'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Kiasi Kipya'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQuantity = int.tryParse(controller.text) ?? 0;
              try {
                await context.read<InventoryProvider>().updateStock(item.id, newQuantity);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hifadhi imesasishwa!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hitilafu: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Badilisha'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Bidhaa'),
            content: Text('Je, una uhakika unataka kufuta "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              bool deleted = false;
              try {
                deleted = await context.read<InventoryProvider>().deleteProduct(item.id);
                if (mounted) {
                  Navigator.pop(context); // Close the dialog
                  if (deleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bidhaa imefutwa!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.read<InventoryProvider>().loadInventory(); // Refresh the list
                  }
                  // If not deleted, the InventoryProvider already showed an error.
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hitilafu: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Futa',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    return Colors.grey; // or any color you want for image backgrounds
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext dialogContext) async {
    final bool? confirm = await showDialog<bool>(
      context: dialogContext,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Thibitisha kutoka'),
          content: const Text('Una uhakika unataka kutoka kwenye akaunti?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hapana'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ndiyo, Toka'),
            ),
          ],
        );
      },
    );
    if (confirm == true && mounted) {
      final authProvider = dialogContext.read<AuthProvider>();
      try {
        await authProvider.logout();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('Imeshindikana kutoka: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('Hitilafu isiyotarajiwa wakati wa kutoka: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
