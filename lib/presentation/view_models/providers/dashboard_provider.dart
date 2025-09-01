import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/services/sync_service.dart';
import 'table_provider.dart';

class LocationSection {
  final String name;
  final IconData icon;
  final Color color;
  LocationSection(this.name, this.icon, this.color);
}

class DashboardProvider extends ChangeNotifier {
  String _selectedLocation = 'All';
  bool _isSyncing = false;
  String? _syncMessage;

  String get selectedLocation => _selectedLocation;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;

  final List<LocationSection> locations = [
    LocationSection('All', Icons.all_inclusive, Colors.grey),
    LocationSection('Main Hall', Icons.home, Colors.blue),
    LocationSection('VIP Section', Icons.star, Colors.purple),
    LocationSection('Terrace', Icons.deck, Colors.orange),
    LocationSection('Garden Area', Icons.local_florist, Colors.green),
    LocationSection('Balcony', Icons.balcony, Colors.teal),
    LocationSection('Private Room', Icons.meeting_room, Colors.red),
  ];

  void changeLocation(String location) {
    _selectedLocation = location;
    notifyListeners();
  }

  Future<void> syncData({TableProvider? tableProvider}) async {
    _isSyncing = true;
    _syncMessage = null;
    notifyListeners();

    try {
      // Sync general data
      final success = await SyncService.syncAllData();
      
      // Also refresh tables if provider is available
      if (tableProvider != null) {
        await tableProvider.refreshTables();
      }
      
      _syncMessage = success
          ? 'Data synced successfully!'
          : 'Sync failed. Please try again.';
    } catch (e) {
      _syncMessage = 'Sync error: ${e.toString()}';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void clearSyncMessage() {
    _syncMessage = null;
    notifyListeners();
  }
}
