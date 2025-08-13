import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tafuta bidhaa...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  _showFilterDialog(context);
                },
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Yote', true),
                const SizedBox(width: 8),
                _buildFilterChip('Hifadhi Chini', false),
                const SizedBox(width: 8),
                ...AppConstants.businessCategories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(category, false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // TODO: Implement filter logic
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chuja Bidhaa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Aina ya Bidhaa'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Show category filter
              },
            ),
            ListTile(
              title: const Text('Bei'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Show price filter
              },
            ),
            ListTile(
              title: const Text('Hifadhi'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Show stock filter
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Apply filters
              Navigator.pop(context);
            },
            child: const Text('Tekeleza'),
          ),
        ],
      ),
    );
  }
}
