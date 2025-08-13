import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/records_provider.dart';

class RecordFilterBar extends StatelessWidget {
  const RecordFilterBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordsProvider>(
      builder: (context, provider, child) {
    return Container(
      padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'all':
                      provider.showAllRecords();
                      break;
                    case 'clear':
                      provider.clearFilters();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(Icons.list),
                        SizedBox(width: 8),
                        Text('Rekodi zote'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
      child: Row(
        children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Futa filta'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.filter_list),
                ),
              ),
            ],
          ),
        );
            },
    );
  }
}
