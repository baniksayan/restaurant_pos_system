import 'package:flutter/material.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/local/models/table_model.dart';
import '../../../services/sync_service.dart';
import '../../../core/utils/uuid_generator.dart';

class TableProvider extends ChangeNotifier {
  List<TableModel> _tables = [];
  bool _isLoading = false;
  String? _error;

  List<TableModel> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize with sample data if no tables exist
  Future<void> initializeTables() async {
    _setLoading(true);
    
    try {
      _tables = HiveService.getAllTables();
      
      // If no tables exist, create sample data
      if (_tables.isEmpty) {
        await _createSampleTables();
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load tables: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createSampleTables() async {
    final sampleTables = [
      TableModel(
        id: UuidGenerator.generate(),
        name: 'Table 1',
        capacity: 4,
        status: 'available',
        lastUpdated: DateTime.now(),
      ),
      TableModel(
        id: UuidGenerator.generate(),
        name: 'Table 2',
        capacity: 2,
        status: 'occupied',
        kotGenerated: true,
        lastUpdated: DateTime.now(),
      ),
      TableModel(
        id: UuidGenerator.generate(),
        name: 'Table 3',
        capacity: 6,
        status: 'available',
        lastUpdated: DateTime.now(),
      ),
      TableModel(
        id: UuidGenerator.generate(),
        name: 'Table 4',
        capacity: 4,
        status: 'occupied',
        kotGenerated: true,
        billGenerated: true,
        lastUpdated: DateTime.now(),
      ),
      TableModel(
        id: UuidGenerator.generate(),
        name: 'Table 5',
        capacity: 8,
        status: 'reserved',
        lastUpdated: DateTime.now(),
      ),
      TableModel(
        id: UuidGenerator.generate(),
        name: 'Table 6',
        capacity: 4,
        status: 'cleaning',
        lastUpdated: DateTime.now(),
      ),
    ];

    for (final table in sampleTables) {
      await HiveService.saveTable(table);
    }
    
    _tables = sampleTables;
  }

  Future<void> updateTableStatus(String tableId, String status) async {
    try {
      await HiveService.updateTableStatus(tableId, status);
      
      // Update local state
      final tableIndex = _tables.indexWhere((t) => t.id == tableId);
      if (tableIndex != -1) {
        _tables[tableIndex].status = status;
        _tables[tableIndex].lastUpdated = DateTime.now();
        notifyListeners();
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to update table: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> occupyTable(String tableId, String orderId) async {
    try {
      final table = HiveService.getTable(tableId);
      if (table != null) {
        table.status = 'occupied';
        table.currentOrderId = orderId;
        table.lastUpdated = DateTime.now();
        await HiveService.saveTable(table);
        
        await initializeTables(); // Refresh list
      }
    } catch (e) {
      _error = 'Failed to occupy table: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> clearTable(String tableId) async {
    try {
      final table = HiveService.getTable(tableId);
      if (table != null) {
        table.status = 'available';
        table.currentOrderId = null;
        table.kotGenerated = false;
        table.billGenerated = false;
        table.lastUpdated = DateTime.now();
        await HiveService.saveTable(table);
        
        await initializeTables(); // Refresh list
      }
    } catch (e) {
      _error = 'Failed to clear table: ${e.toString()}';
      notifyListeners();
    }
  }

  List<TableModel> getTablesForLocation(String location) {
    // Filter tables based on location if needed
    // For now, return all tables
    return _tables;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
