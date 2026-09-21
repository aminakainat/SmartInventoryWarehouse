import 'dart:async';
import 'package:flutter/foundation.dart';

// --- MODELS ---

class Product {
  final String id;
  String name;
  String sku;
  String barcode;
  String category;
  int quantity;
  double price;
  String location;
  List<String> images;
  bool isSynced;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.quantity,
    required this.price,
    required this.location,
    required this.images,
    this.isSynced = true,
  });

  Product copyWith({
    String? name,
    String? sku,
    String? barcode,
    String? category,
    int? quantity,
    double? price,
    String? location,
    List<String>? images,
    bool? isSynced,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      location: location ?? this.location,
      images: images ?? this.images,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class InvoiceItem {
  final Product product;
  int quantity;

  InvoiceItem({required this.product, required this.quantity});

  double get total => product.price * quantity;
}

class Invoice {
  final String id;
  final String customerName;
  final String customerPhone;
  final List<InvoiceItem> items;
  final double discount;
  final double taxRate;
  final String paymentMethod;
  final DateTime date;
  bool isSynced;

  Invoice({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.discount,
    required this.taxRate,
    required this.paymentMethod,
    required this.date,
    this.isSynced = true,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * (discount / 100);
  double get taxAmount => (subtotal - discountAmount) * (taxRate / 100);
  double get grandTotal => subtotal - discountAmount + taxAmount;
}

class StockMoveLog {
  final String id;
  final String sku;
  final String productName;
  final String type; // 'INCOMING', 'OUTGOING', 'TRANSFER', 'ADJUSTMENT'
  final int quantityDelta;
  final String sourceLocation;
  final String destLocation;
  final DateTime timestamp;
  final String user;

  StockMoveLog({
    required this.id,
    required this.sku,
    required this.productName,
    required this.type,
    required this.quantityDelta,
    required this.sourceLocation,
    required this.destLocation,
    required this.timestamp,
    required this.user,
  });
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'STOCK', 'SYNC', 'BILLING', 'SYSTEM'
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

class SyncConflict {
  final Product localProduct;
  final Product serverProduct;
  final String reason;

  SyncConflict({
    required this.localProduct,
    required this.serverProduct,
    required this.reason,
  });
}

class BluetoothPrinter {
  final String name;
  final String address;
  bool isConnected;

  BluetoothPrinter({
    required this.name,
    required this.address,
    this.isConnected = false,
  });
}

// --- CORE MOCK SERVICE ---

class MockService extends ChangeNotifier {
  // Connectivity
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  set isOnline(bool val) {
    if (_isOnline != val) {
      _isOnline = val;
      notifyListeners();
      if (_isOnline) {
        // Auto sync after a small delay
        triggerAutoSync();
      }
    }
  }

  final String _currentUser = "Amina kainat";
  String get currentUser => _currentUser;
  final String _userRole = "Warehouse Manager";
  String get userRole => _userRole;
  final String _assignedWarehouse = "Central Zone (WH-01)";
  String get assignedWarehouse => _assignedWarehouse;

  bool isBiometricEnabled = true;
  bool isPinLocked = false;
  String currentPin = "1234";
  final List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);

  final List<Invoice> _invoices = [];
  List<Invoice> get invoices => List.unmodifiable(_invoices);

  final List<StockMoveLog> _stockLogs = [];
  List<StockMoveLog> get stockLogs => List.unmodifiable(_stockLogs);

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  final List<SyncConflict> _conflicts = [];
  List<SyncConflict> get conflicts => List.unmodifiable(_conflicts);

  final List<String> _scanHistory = [];
  List<String> get scanHistory => List.unmodifiable(_scanHistory);

  final List<BluetoothPrinter> printers = [
    BluetoothPrinter(
      name: "Zebra ZQ520 Mobile Printer",
      address: "00:22:58:3B:A1:4D",
    ),
    BluetoothPrinter(name: "Bixolon SPP-R310", address: "12:34:56:78:9A:BC"),
    BluetoothPrinter(
      name: "Epson TM-P20 Battery Printer",
      address: "AA:BB:CC:DD:EE:FF",
    ),
  ];

  double latitude = 37.7749;
  double longitude = -122.4194;
  bool isTrackingLocation = true;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  double syncProgress = 0.0;
  DateTime lastSyncTime = DateTime.now().subtract(const Duration(minutes: 15));

  Timer? _liveEngineTimer;

  MockService() {
    _loadSeedData();
    _startLiveSimulationEngine();
  }

  void _startLiveSimulationEngine() {
    _liveEngineTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _simulateLiveWarehouseEvent();
    });
  }

  void _simulateLiveWarehouseEvent() {
    if (_products.isEmpty) return;

    final index = DateTime.now().second % _products.length;
    final product = _products[index];
    final eventType = DateTime.now().millisecond % 3;

    if (eventType == 0) {
      final addQty = 5 + (DateTime.now().second % 15);
      final newQty = product.quantity + addQty;
      _products[index] = product.copyWith(
        quantity: newQty,
        isSynced: _isOnline,
      );

      _stockLogs.insert(
        0,
        StockMoveLog(
          id: "L_LIVE_${DateTime.now().millisecondsSinceEpoch}",
          sku: product.sku,
          productName: product.name,
          type: "INCOMING",
          quantityDelta: addQty,
          sourceLocation: "External Logistics Gate",
          destLocation: product.location,
          timestamp: DateTime.now(),
          user: "RFID Gate Sensor",
        ),
      );

      addNotification(
        "RFID Inbound Gate Scan",
        "Automated gate scanner captured arrival of $addQty units of '${product.name}' in real-time.",
        "STOCK",
      );
    } else if (eventType == 1) {
      if (product.quantity > 10) {
        final sellQty = 1 + (DateTime.now().second % 3);
        final newQty = product.quantity - sellQty;
        _products[index] = product.copyWith(
          quantity: newQty,
          isSynced: _isOnline,
        );

        _stockLogs.insert(
          0,
          StockMoveLog(
            id: "L_LIVE_${DateTime.now().millisecondsSinceEpoch}",
            sku: product.sku,
            productName: product.name,
            type: "OUTGOING",
            quantityDelta: -sellQty,
            sourceLocation: product.location,
            destLocation: "Central Dispatch Hub",
            timestamp: DateTime.now(),
            user: "POS Counter Checkout",
          ),
        );

        addNotification(
          "POS Dispatch Complete",
          "Sales terminal dispatched $sellQty units of '${product.name}' in real-time.",
          "BILLING",
        );
      }
    } else {
      addNotification(
        "Warehouse Telemetry Scan",
        "Storage location bin '${product.location}' diagnostics check: 18.5°C, 45% humidity status OK.",
        "SYSTEM",
      );
    }

    notifyListeners();
  }

  void _loadSeedData() {
    _products.addAll([
      Product(
        id: "1",
        name: "Premium RFID Pallet Tag",
        sku: "PLT-RFID-001",
        barcode: "880947623910",
        category: "RF Tags & Sensors",
        quantity: 120,
        price: 4.99,
        location: "Aisle A, Shelf 2",
        images: [],
      ),
      Product(
        id: "2",
        name: "Industrial Forklift Battery XL",
        sku: "BAT-FORK-770",
        barcode: "079357318944",
        category: "Machinery Parts",
        quantity: 4,
        price: 2450.00,
        location: "Power Zone East",
        images: [],
      ),
      Product(
        id: "3",
        name: "Corrugated Box Heavy Duty 20x20",
        sku: "BOX-HD-2020",
        barcode: "690123456789",
        category: "Packaging Supplies",
        quantity: 850,
        price: 1.85,
        location: "Aisle D, Row 4",
        images: [],
      ),
      Product(
        id: "4",
        name: "Smart Barcode Handheld Scanner",
        sku: "SCN-BT-800",
        barcode: "400638133393",
        category: "Hardware Devices",
        quantity: 15,
        price: 189.00,
        location: "Aisle B, Shelf 1",
        images: [],
      ),
      Product(
        id: "5",
        name: "Steel Packing Wire roll (500m)",
        sku: "WIRE-STEEL-500",
        barcode: "490250562145",
        category: "Packaging Supplies",
        quantity: 50,
        price: 34.50,
        location: "Aisle D, Row 1",
        images: [],
      ),
    ]);

    _stockLogs.addAll([
      StockMoveLog(
        id: "L1",
        sku: "PLT-RFID-001",
        productName: "Premium RFID Pallet Tag",
        type: "INCOMING",
        quantityDelta: 100,
        sourceLocation: "Supplier Direct",
        destLocation: "Aisle A, Shelf 2",
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        user: "Admin Sync",
      ),
      StockMoveLog(
        id: "L2",
        sku: "BAT-FORK-770",
        productName: "Industrial Forklift Battery XL",
        type: "ADJUSTMENT",
        quantityDelta: -1,
        sourceLocation: "Power Zone East",
        destLocation: "Power Zone East",
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        user: "John Doe",
      ),
      StockMoveLog(
        id: "L3",
        sku: "SCN-BT-800",
        productName: "Smart Barcode Handheld Scanner",
        type: "TRANSFER",
        quantityDelta: 5,
        sourceLocation: "Secondary WH-02",
        destLocation: "Aisle B, Shelf 1",
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        user: "John Doe",
      ),
    ]);

    _notifications.addAll([
      AppNotification(
        id: "N1",
        title: "Critical Low Stock Alert",
        message:
            "Industrial Forklift Battery XL quantity is 4. Reorder threshold is 5.",
        type: "STOCK",
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      AppNotification(
        id: "N2",
        title: "Backup Complete",
        message: "Offline database backup successfully encrypted and cached.",
        type: "SYSTEM",
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }

  void addProduct(Product prod) {
    _products.add(prod);
    _stockLogs.insert(
      0,
      StockMoveLog(
        id: "L_${DateTime.now().millisecondsSinceEpoch}",
        sku: prod.sku,
        productName: prod.name,
        type: "INCOMING",
        quantityDelta: prod.quantity,
        sourceLocation: "Initial Input",
        destLocation: prod.location,
        timestamp: DateTime.now(),
        user: _currentUser,
      ),
    );
    notifyListeners();
    _checkLowStock(prod);
  }

  void updateProduct(Product prod) {
    int idx = _products.indexWhere((p) => p.id == prod.id);
    if (idx != -1) {
      final old = _products[idx];
      int delta = prod.quantity - old.quantity;
      _products[idx] = prod;

      if (delta != 0) {
        _stockLogs.insert(
          0,
          StockMoveLog(
            id: "L_${DateTime.now().millisecondsSinceEpoch}",
            sku: prod.sku,
            productName: prod.name,
            type: "ADJUSTMENT",
            quantityDelta: delta,
            sourceLocation: old.location,
            destLocation: prod.location,
            timestamp: DateTime.now(),
            user: _currentUser,
          ),
        );
      }
      notifyListeners();
      _checkLowStock(prod);
    }
  }

  void deleteProduct(String id) {
    final prod = _products.firstWhere((element) => element.id == id);
    _stockLogs.insert(
      0,
      StockMoveLog(
        id: "L_${DateTime.now().millisecondsSinceEpoch}",
        sku: prod.sku,
        productName: prod.name,
        type: "OUTGOING",
        quantityDelta: -prod.quantity,
        sourceLocation: prod.location,
        destLocation: "Disposal / Deleted",
        timestamp: DateTime.now(),
        user: _currentUser,
      ),
    );
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void adjustStock(String id, int quantityDelta, String reason) {
    int idx = _products.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final old = _products[idx];
      final newQty = (old.quantity + quantityDelta).clamp(0, 999999);
      _products[idx] = old.copyWith(quantity: newQty, isSynced: false);
      _stockLogs.insert(
        0,
        StockMoveLog(
          id: "L_${DateTime.now().millisecondsSinceEpoch}",
          sku: old.sku,
          productName: old.name,
          type: "ADJUSTMENT",
          quantityDelta: quantityDelta,
          sourceLocation: old.location,
          destLocation: old.location,
          timestamp: DateTime.now(),
          user: _currentUser,
        ),
      );
      notifyListeners();
      _checkLowStock(_products[idx]);
    }
  }

  void transferStock(String id, int qty, String destLoc) {
    int idx = _products.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final old = _products[idx];
      _stockLogs.insert(
        0,
        StockMoveLog(
          id: "L_${DateTime.now().millisecondsSinceEpoch}",
          sku: old.sku,
          productName: old.name,
          type: "TRANSFER",
          quantityDelta: qty,
          sourceLocation: old.location,
          destLocation: destLoc,
          timestamp: DateTime.now(),
          user: _currentUser,
        ),
      );
      _products[idx] = old.copyWith(location: destLoc, isSynced: false);
      notifyListeners();
    }
  }

  void _checkLowStock(Product prod) {
    if (prod.quantity <= 5) {
      final title = "Low Stock Alert: ${prod.name}";
      final message =
          "Current stock level is ${prod.quantity}. Consider replenishing.";
      if (!_notifications.any((n) => n.title == title && !n.isRead)) {
        addNotification(title, message, "STOCK");
      }
    }
  }

  void addNotification(String title, String message, String type) {
    final note = AppNotification(
      id: "N_${DateTime.now().millisecondsSinceEpoch}",
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, note);
    notifyListeners();
  }

  void markAllNotificationsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void createInvoice(Invoice invoice) {
    _invoices.insert(0, invoice);
    for (var item in invoice.items) {
      int prodIdx = _products.indexWhere((p) => p.id == item.product.id);
      if (prodIdx != -1) {
        final p = _products[prodIdx];
        _products[prodIdx] = p.copyWith(
          quantity: (p.quantity - item.quantity).clamp(0, 999999),
          isSynced: false,
        );
        _stockLogs.insert(
          0,
          StockMoveLog(
            id: "L_${DateTime.now().millisecondsSinceEpoch}",
            sku: p.sku,
            productName: p.name,
            type: "OUTGOING",
            quantityDelta: -item.quantity,
            sourceLocation: p.location,
            destLocation: "Client Sale (${invoice.customerName})",
            timestamp: DateTime.now(),
            user: _currentUser,
          ),
        );
        _checkLowStock(_products[prodIdx]);
      }
    }
    notifyListeners();

    if (!_isOnline) {
      addNotification(
        "Offline Invoice Saved",
        "Invoice #${invoice.id} cached locally. It will auto-sync when online.",
        "BILLING",
      );
    } else {
      addNotification(
        "Invoice Dispatched",
        "Invoice #${invoice.id} sent successfully to central ERP.",
        "BILLING",
      );
    }
  }

  void recordScan(String val) {
    _scanHistory.insert(0, val);
    notifyListeners();
  }

  void simulateRouteTravel() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!isTrackingLocation) {
        timer.cancel();
        return;
      }
      latitude += (0.0005 - (0.001 * (DateTime.now().second % 3)));
      longitude += (0.0005 - (0.001 * (DateTime.now().second % 2)));
      notifyListeners();
    });
  }

  void togglePrinterConnection(int idx) {
    final status = printers[idx].isConnected;
    for (var p in printers) {
      p.isConnected = false;
    }
    printers[idx].isConnected = !status;
    notifyListeners();
  }

  void clearLocalCache() {
    _products.clear();
    _invoices.clear();
    _stockLogs.clear();
    _conflicts.clear();
    _scanHistory.clear();
    _loadSeedData();
    notifyListeners();
    addNotification(
      "Database Reset",
      "Local Hive and SQLite databases rebuilt successfully.",
      "SYSTEM",
    );
  }

  void triggerAutoSync() {
    if (_isOnline && (hasUnsyncedData || _conflicts.isNotEmpty)) {
      syncOfflineData();
    }
  }

  bool get hasUnsyncedData {
    bool unsyncedInvoices = _invoices.any((inv) => !inv.isSynced);
    bool unsyncedProducts = _products.any((p) => !p.isSynced);
    return unsyncedInvoices || unsyncedProducts;
  }

  Future<void> syncOfflineData() async {
    if (_isSyncing) return;
    _isSyncing = true;
    syncProgress = 0.0;
    notifyListeners();
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      syncProgress = i / 5.0;
      notifyListeners();
    }
    if (_products.isNotEmpty && _conflicts.isEmpty) {
      final conflictProd = _products.first;
      _conflicts.add(
        SyncConflict(
          localProduct: conflictProd.copyWith(
            quantity: conflictProd.quantity,
            isSynced: false,
          ),
          serverProduct: conflictProd.copyWith(
            quantity: conflictProd.quantity + 40,
            isSynced: true,
          ),
          reason:
              "Server quantity was updated by operator 'Jane Doe' in WH-02 during offline interval.",
        ),
      );
    }
    for (var p in _products) {
      p.isSynced = true;
    }
    for (var inv in _invoices) {
      inv.isSynced = true;
    }

    lastSyncTime = DateTime.now();
    _isSyncing = false;
    notifyListeners();

    addNotification(
      "Sync Complete",
      _conflicts.isNotEmpty
          ? "Synchronization completed with ${_conflicts.length} conflict(s) resolved."
          : "All database tables synchronized successfully with the central SAP repository.",
      "SYNC",
    );
  }

  void resolveConflict(int index, bool keepLocal) {
    if (index >= 0 && index < _conflicts.length) {
      final conflict = _conflicts[index];
      if (keepLocal) {
        int idx = _products.indexWhere((p) => p.id == conflict.localProduct.id);
        if (idx != -1) {
          _products[idx].isSynced = true;
        }
      } else {
        int idx = _products.indexWhere(
          (p) => p.id == conflict.serverProduct.id,
        );
        if (idx != -1) {
          _products[idx] = conflict.serverProduct;
        }
      }
      _conflicts.removeAt(index);
      notifyListeners();
      addNotification(
        "Conflict Resolved",
        "Local database cache updated with selected resolution.",
        "SYNC",
      );
    }
  }

  void simulateManualConflict() {
    if (_products.isNotEmpty) {
      final conflictProd = _products.first;
      _conflicts.add(
        SyncConflict(
          localProduct: conflictProd.copyWith(
            quantity: conflictProd.quantity,
            isSynced: false,
          ),
          serverProduct: conflictProd.copyWith(
            quantity: conflictProd.quantity - 15,
            isSynced: true,
          ),
          reason:
              "Conflict: Server records indicate a stock reduction due to a direct sale from ERP.",
        ),
      );
      notifyListeners();
      addNotification(
        "Sync Alert",
        "1 Synchronization conflict detected.",
        "SYNC",
      );
    }
  }

  @override
  void dispose() {
    _liveEngineTimer?.cancel();
    super.dispose();
  }
}
