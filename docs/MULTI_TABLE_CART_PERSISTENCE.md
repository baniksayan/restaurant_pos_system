# Multi-Table Cart Persistence Implementation

## Overview
This document describes the implementation of persistent cart storage across multiple tables in the restaurant POS system.

## Problem Statement
The user reported two critical issues:
1. **Cart Clearing Between Tables**: When items are added to a cart but no KOT is generated, the cart clears when switching to that table from another table.
2. **Bill Amount Loss**: After generating a bill for one table and switching to another table, coming back to the first table shows "bill amount: null" error.

## Solution Implementation

### 1. Enhanced AnimatedCartProvider

#### Table-Wise Cart Storage
- Added `_tableWiseCarts` map to store cart data per table ID
- Added `_tableWiseServerKotItems` map to store server KOT items per table ID
- Modified `switchToTable()` method to save/load cart state per table

#### Persistent Storage Integration
- Added `_saveCartToPersistentStorage()` method to save cart data to Hive storage
- Added `_loadCartFromPersistentStorage()` method to load cart data from Hive storage
- Cart data is automatically saved when switching tables
- Cart data is loaded from persistent storage if not found in memory

#### Key Methods
```dart
void switchToTable(String? newTableId) {
  // Save current cart state to persistent storage
  if (_currentTableId != null) {
    _saveCartToPersistentStorage(_currentTableId!);
  }
  
  // Load cart for new table from memory or persistent storage
  // ...
}
```

### 2. Enhanced HiveService

#### Added Table-Wise Storage Methods
- `saveTableCart(String tableId, Map<String, dynamic> cartData)`: Save cart data per table
- `getTableCart(String tableId)`: Retrieve cart data for a specific table
- `clearTableCart(String tableId)`: Clear cart data for a specific table
- `saveTableBillAmount(String tableId, double billAmount)`: Save bill amount per table
- `getTableBillAmount(String tableId)`: Retrieve bill amount for a specific table
- `clearTableBillAmount(String tableId)`: Clear bill amount for a specific table

#### Storage Structure
- Cart data stored with key: `cart_{tableId}`
- Bill amounts stored with key: `bill_amount_{tableId}`
- All data persists across app sessions using Hive local database

### 3. Enhanced TableProvider

#### Bill Amount Persistence
- Modified `storeBillAmount()` method to save to persistent storage
- Modified `getBillAmount()` method to fallback to persistent storage
- Bill amounts are now preserved when switching between tables

#### Key Enhancements
```dart
void storeBillAmount(String tableId, double billAmount) {
  // Save to persistent storage first
  HiveService.saveTableBillAmount(tableId, billAmount);
  // ... update in-memory state
}

double? getBillAmount(String tableId) {
  // Check in-memory first, fallback to persistent storage
  if (table.billAmount == null) {
    final persistedAmount = HiveService.getTableBillAmount(tableId);
    // ... update in-memory state if found
  }
}
```

### 4. MenuProvider Changes
- Removed cart tracking functionality to prevent auto-selection
- `getCartQuantity()` now always returns 0
- Cart management is exclusively handled by AnimatedCartProvider

## Data Flow

### Table Switching Process
1. User switches from Table A to Table B
2. Current cart state (Table A) is saved to persistent storage
3. Cart is cleared and loaded with Table B data from memory
4. If no memory data exists, load from persistent storage
5. Server KOT items are also loaded for Table B
6. UI updates to show Table B cart state

### Cart Persistence Process
1. Items added to cart are stored in memory (`_tableWiseCarts`)
2. When switching tables, cart data is serialized to JSON and saved to Hive
3. Cart includes all item properties: ID, name, price, quantity, KOT status, etc.
4. On app restart or table switch, data is loaded from Hive storage

### Bill Amount Persistence Process
1. When bill is generated, amount is saved to both memory and persistent storage
2. When switching tables, bill amounts remain accessible via persistent storage
3. If table bill amount is null in memory, system checks persistent storage
4. Bill amounts persist across app sessions and table switches

## Benefits

1. **No Data Loss**: Cart items are preserved when switching between tables
2. **Session Persistence**: Data survives app restarts and crashes  
3. **Multi-Table Support**: Each table maintains independent cart and bill state
4. **KOT Status Tracking**: Proper distinction between KOT'd and new items
5. **Fallback Mechanism**: Memory-first approach with persistent storage fallback

## Technical Details

### Dependencies
- `hive_flutter`: Local database storage
- `provider`: State management
- Custom CartItem model with KOT status tracking

### Storage Format
```dart
// Cart data structure
{
  'itemId1': {
    'id': 'item123',
    'name': 'Burger',
    'price': 10.0,
    'quantity': 2,
    'tableId': 'table1',
    'isKotGenerated': false,
    'kotNumber': null,
    // ... other properties
  }
}

// Bill amount: double value
billAmount: 150.50
```

### Error Handling
- Try-catch blocks around all storage operations
- Debug logging for troubleshooting
- Graceful fallbacks if storage operations fail
- Null safety checks throughout

## Usage

### For Developers
The implementation is transparent to the UI layer. Simply use:
- `AnimatedCartProvider.switchToTable(tableId)` for table switching
- `TableProvider.storeBillAmount(tableId, amount)` for bill storage
- `TableProvider.getBillAmount(tableId)` for bill retrieval

### For Users
- Add items to any table's cart
- Switch between tables without losing cart data
- Generate bills and amounts are preserved across table switches
- App restart preserves all cart and bill data

## Future Enhancements
- Automatic cleanup of old cart data
- Cloud synchronization for multi-device support
- Cart sharing between waiters
- Advanced conflict resolution for concurrent edits
