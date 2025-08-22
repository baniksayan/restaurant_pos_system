// lib/presentation/views/table_management/tables_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/providers/table_provider.dart';

class TablesView extends StatefulWidget {
  const TablesView({super.key});

  @override
  State<TablesView> createState() => _TablesViewState();
}

class _TablesViewState extends State<TablesView> {
  @override
  void initState() {
    super.initState();
    _testAPI();
  }

  void _testAPI() {
    final tableProvider = Provider.of<TableProvider>(context, listen: false);

    const String token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb21wYW55X2lkIjoiaEdFOXAyTnMzdVVTdS9nM3dpdVpWQT09IiwibmJmIjoxNzU1NzY4NjI5LCJleHAiOjE3NTU4NTUwMjksImlhdCI6MTc1NTc2ODYyOX0.E46nK0KzuGHM6LPJop2tq3oq-eadiBoHIpLwAbtSaXg";
    const int outletId = 55;

    print("🔥 CALLING API NOW...");
    tableProvider.fetchTablesByOutlet(token: token, outletId: outletId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API TEST - Tables'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _testAPI),
        ],
      ),
      body: Consumer<TableProvider>(
        builder: (context, tableProvider, child) {
          print(
            "🚀 Build called - isApiLoading: ${tableProvider.isApiLoading}",
          );
          print("🚀 Error: ${tableProvider.tableApiError}");
          print("🚀 Tables count: ${tableProvider.orderChannels.length}");

          if (tableProvider.isApiLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('🔄 Loading API...'),
                ],
              ),
            );
          }

          if (tableProvider.tableApiError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('❌ Error: ${tableProvider.tableApiError}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _testAPI,
                    child: const Text('🔄 Retry'),
                  ),
                ],
              ),
            );
          }

          final tables = tableProvider.orderChannels;

          if (tables.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_restaurant, size: 64),
                  SizedBox(height: 16),
                  Text('📋 No API data received'),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green.withOpacity(0.1),
                child: Text(
                  '✅ API SUCCESS! Found ${tables.length} tables',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('🏷️ ${table.name}'),
                        subtitle: Text(
                          '📍 ${table.channelType} | 👥 ${table.capacity}',
                        ),
                        trailing: Text('📋 Orders: ${table.orderList.length}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
