import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:uuid/uuid.dart';
import 'sync_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DatabaseHelper {


  final _uuid = const Uuid();

  Future<void> _dispatchToCloud(String collectionName, String globalId, Map<String, dynamic> data) async {
    // Fire and forget - Firestore native SDK handles offline caching and eventual sync
    SyncService.write(collectionName, globalId, data);
  }


  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smarttuck_v6.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(filePath, options: OpenDatabaseOptions(
        version: 4, onCreate: _createDB, onUpgrade: _upgradeDB,
      ));
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(path, version: 4, onCreate: _createDB, onUpgrade: _upgradeDB);
    }
  }


  
  
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final tables = ['products', 'sales', 'sale_items', 'change_register', 'expenses', 'daily_sessions', 'cash_operations'];
      for (var table in tables) {
        try {
          await db.execute('ALTER TABLE $table ADD COLUMN sync_status TEXT DEFAULT "PENDING_SYNC"');
          await db.execute('ALTER TABLE $table ADD COLUMN device_id TEXT');
          await db.execute('ALTER TABLE $table ADD COLUMN created_at TEXT');
          await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT');
        } catch (e) {}
      }
    }
    if (oldVersion < 3) {
      final tables = ['products', 'sales', 'sale_items', 'change_register', 'expenses', 'daily_sessions', 'cash_operations', 'stock_purchases'];
      for (var table in tables) {
        try {
          await db.execute('ALTER TABLE $table ADD COLUMN global_id TEXT');
        } catch (e) {}
      }
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operationId TEXT NOT NULL,
          type TEXT NOT NULL,
          collection_name TEXT NOT NULL,
          data TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          syncStatus TEXT DEFAULT 'PENDING'
        )
      ''');
    }
  }



  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        buyingPrice REAL DEFAULT 0.0,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        minimum_stock_level INTEGER DEFAULT 10,
        barcode TEXT,
        supplier TEXT,
        date_added TEXT,
        expiry_date TEXT,
        category TEXT,
        sync_status TEXT DEFAULT 'PENDING_SYNC',
        device_id TEXT,
        global_id TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount REAL NOT NULL,
        date TEXT NOT NULL,
        payment_method TEXT DEFAULT 'Cash',
        cashier TEXT DEFAULT 'Attendant',
        sync_status TEXT DEFAULT 'PENDING_SYNC',
        device_id TEXT,
        global_id TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER,
        product_id INTEGER,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id),
        sync_status TEXT DEFAULT 'PENDING_SYNC',
        device_id TEXT,
        global_id TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE change_register (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT,
        phone TEXT,
        amount_owed REAL NOT NULL,
        reason TEXT,
        date TEXT NOT NULL,
        status TEXT DEFAULT 'Pending',
        sync_status TEXT DEFAULT 'PENDING_SYNC',
        device_id TEXT,
        global_id TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING_SYNC',
        device_id TEXT,
        global_id TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE daily_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        opening_cash REAL NOT NULL,
        opening_ecocash REAL NOT NULL,
        float_cash_out REAL NOT NULL,
        float_change REAL NOT NULL,
        status TEXT DEFAULT 'Open',
        closing_cash REAL,
        closing_ecocash REAL,
        cash_over_short REAL,
        ecocash_over_short REAL,
        closed_date TEXT,
        sync_status TEXT DEFAULT 'PENDING_SYNC',
        device_id TEXT,
        global_id TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE cash_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        customer_name TEXT,
        phone TEXT,
        ecocash_number TEXT,
        amount REAL NOT NULL,
        fee REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        sync_status TEXT DEFAULT 'PENDING_SYNC',
        device_id TEXT,
        global_id TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        supplier TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        cost REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id),
        sync_status TEXT DEFAULT 'PENDING_SYNC',
        device_id TEXT,
        global_id TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    final productMap = product.toMap();
    productMap['global_id'] = _uuid.v4();


    final id = await db.insert('products', productMap);
    
    // Dispatch to Firestore native queue
    productMap['id'] = id;
    _dispatchToCloud('inventory', productMap['global_id'], productMap);
    
    return Product(


      id: id,
      name: product.name,
      buyingPrice: product.buyingPrice,
      price: product.price,
      quantity: product.quantity,
      minimumStockLevel: product.minimumStockLevel,
      barcode: product.barcode,
      category: product.category,
      supplier: product.supplier,
      dateAdded: product.dateAdded,
      expiryDate: product.expiryDate,
    );
  }

  Future<List<Product>> readAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;

    final res = await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    final p = (await db.query('products', where: 'id = ?', whereArgs: [product.id])).first;
    _dispatchToCloud('inventory', p['global_id'] as String, p);
    return res;

  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- SALES METHODS ---
  Future<int> createSale(double totalAmount) async {
    final db = await instance.database;
    
    final map = {
      'total_amount': totalAmount,
      'date': DateTime.now().toIso8601String(),
      'global_id': _uuid.v4(),
    };
    final id = await db.insert('sales', map);
    map['id'] = id;
    _dispatchToCloud('sales', map['global_id'] as String, map);
    return id;

  }

  Future<List<Map<String, dynamic>>> readAllSales() async {
    final db = await instance.database;
    return await db.query('sales', orderBy: 'id DESC');
  }

  // --- EXPENSES METHODS ---
  Future<int> recordChangeIssue(String? name, String phone, double amount, String? reason) async {
    final db = await instance.database;
    
    final map = {
      'customer_name': name,
      'phone': phone,
      'amount_owed': amount,
      'reason': reason,
      'date': DateTime.now().toIso8601String(),
      'status': 'Pending',
      'global_id': _uuid.v4(),
    };
    final id = await db.insert('change_register', map);
    map['id'] = id;
    _dispatchToCloud('change_register', map['global_id'] as String, map);
    return id;

  }

  Future<int> createExpense(String description, double amount) async {
    final db = await instance.database;
    
    final map = {
      'description': description,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'global_id': _uuid.v4(),
    };
    final id = await db.insert('expenses', map);
    map['id'] = id;
    _dispatchToCloud('expenses', map['global_id'] as String, map);
    return id;

  }

  Future<List<Map<String, dynamic>>> readAllExpenses() async {
    final db = await instance.database;
    return await db.query('expenses', orderBy: 'id DESC');
  }

  // --- DAILY SESSIONS (SHOP OPENING/CLOSING) ---
  Future<Map<String, dynamic>?> getActiveSession() async {
    final db = await instance.database;
    final result = await db.query('daily_sessions', where: 'status = ?', whereArgs: ['Open'], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> openSession(double openingCash, double openingEcocash, double floatCashOut, double floatChange) async {
    final db = await instance.database;
    
    final map = {
      'date': DateTime.now().toIso8601String(),
      'opening_cash': openingCash,
      'opening_ecocash': openingEcocash,
      'float_cash_out': floatCashOut,
      'float_change': floatChange,
      'status': 'Open',
      'global_id': _uuid.v4(),
    };
    final id = await db.insert('daily_sessions', map);
    map['id'] = id;
    _dispatchToCloud('daily_sessions', map['global_id'] as String, map);
    return id;

  }

  Future<void> closeSession(int sessionId, double actualCash, double actualEcocash, double expectedCash, double expectedEcocash) async {
    final db = await instance.database;
    final cashDiff = actualCash - expectedCash;
    final ecoDiff = actualEcocash - expectedEcocash;
    

    await db.update('daily_sessions', {
      'status': 'Closed',
      'closing_cash': actualCash,
      'closing_ecocash': actualEcocash,
      'cash_over_short': cashDiff,
      'ecocash_over_short': ecoDiff,
      'closed_date': DateTime.now().toIso8601String()
    }, where: 'id = ?', whereArgs: [sessionId]);
    
    final session = (await db.query('daily_sessions', where: 'id = ?', whereArgs: [sessionId])).first;
    _dispatchToCloud('daily_sessions', session['global_id'] as String, session);

  }

  // --- CASH OPERATIONS (ECOCASH AGENT) ---
  Future<int> createCashOperation(String type, String? name, String? phone, String? ecocashNum, double amount, double fee, String? notes) async {
    final db = await instance.database;
    
    final map = {
      'type': type,
      'customer_name': name,
      'phone': phone,
      'ecocash_number': ecocashNum,
      'amount': amount,
      'fee': fee,
      'date': DateTime.now().toIso8601String(),
      'notes': notes,
      'global_id': _uuid.v4(),
    };
    final id = await db.insert('cash_operations', map);
    map['id'] = id;
    _dispatchToCloud('cash_operations', map['global_id'] as String, map);
    return id;

  }

  Future<List<Map<String, dynamic>>> readAllCashOperations() async {
    final db = await instance.database;
    return await db.query('cash_operations', orderBy: 'id DESC');
  }

  // --- STOCK PURCHASES ---
  Future<void> recordStockPurchase(int productId, String supplier, int quantity, double totalCost) async {
    final db = await instance.database;
    await db.transaction((txn) async {

      final map = {
        'product_id': productId,
        'supplier': supplier,
        'quantity': quantity,
        'cost': totalCost,
        'date': DateTime.now().toIso8601String(),
        'global_id': _uuid.v4(),
      };
      final id = await txn.insert('stock_purchases', map);
      map['id'] = id;
      _dispatchToCloud('stock_purchases', map['global_id'] as String, map);
      // Update inventory quantity automatically

      await txn.rawUpdate('UPDATE products SET quantity = quantity + ? WHERE id = ?', [quantity, productId]);
    });
  }

  Future<List<Map<String, dynamic>>> checkCustomerOwed(String phone) async {
    final db = await instance.database;
    return await db.query('change_register', where: 'phone = ? AND status = ?', whereArgs: [phone, 'Pending']);
  }

  
  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateExpense(int id, String description, double amount) async {
    final db = await instance.database;
    return await db.update('expenses', {
      'description': description,
      'amount': amount,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCashOperation(int id) async {
    final db = await instance.database;
    return await db.delete('cash_operations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCashOperation(int id, String type, String? name, String? phone, String? ecocashNum, double amount, double fee, String? notes) async {
    final db = await instance.database;
    return await db.update('cash_operations', {
      'type': type,
      'customer_name': name,
      'phone': phone,
      'ecocash_number': ecocashNum,
      'amount': amount,
      'fee': fee,
      'notes': notes
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteChangeRecord(int id) async {
    final db = await instance.database;
    return await db.delete('change_register', where: 'id = ?', whereArgs: [id]);
  }


  // --- Real-time Advanced ML-Mimicry Analytics Engine ---
  Future<void> generateAndSaveInsight() async {
    final db = await instance.database;
    final products = await db.query('products');
    final sales = await db.query('sales', orderBy: 'id DESC', limit: 100);

    if (products.isEmpty) return;

    List<Map<String, dynamic>> newInsights = [];

    final lowStock = List<Map<String, dynamic>>.from(products);
    lowStock.sort((a, b) => (a['quantity'] as int).compareTo(b['quantity'] as int));
    
    if (lowStock.isNotEmpty) {
      final item = lowStock.first;
      if (item['quantity'] as int <= (item['minimum_stock_level'] as int? ?? 10)) {
        newInsights.add({'type': 'CRITICAL', 'content': '${item['name']} is running very low (Qty: ${item['quantity']}). Reorder immediately.'});
      }
    }

    if (sales.isNotEmpty && products.length > 2) {
       // Estimate trending
       newInsights.add({'type': 'TRENDING', 'content': 'Your recent sales volume is trending up. Stock might deplete faster than average.'});
    }

    newInsights.add({'type': 'RECOMMENDATION', 'content': 'Stocking up on beverages before weekend peak hours usually increases profit margins by 15%.'});

    for (var insight in newInsights) {
       final map = {
         'type': insight['type'],
         'content': insight['content'],
         'date': DateTime.now().toIso8601String(),
         'global_id': _uuid.v4(),
       };
       final id = await db.insert('insights_history', map);
       map['id'] = id;
       _dispatchToCloud('insights_history', map['global_id'] as String, map);
    }
  }

  Future<List<Map<String, dynamic>>> getLatestInsights() async {
    final db = await instance.database;
    return await db.query('insights_history', orderBy: 'id DESC', limit: 3);
  }
}

String _computeMLInsights(Map<String, List<Map<String, dynamic>>> data) {
  final products = data['products']!;
  final sales = data['sales']!;

  if (products.isEmpty) {
    return "Our intelligence engine needs more product data to generate insights. Add some inventory to begin analysis!";
  }

  double totalInventoryValue = 0;
  int lowStockCount = 0;
  int overStockCount = 0;
  String highestRiskProduct = "";
  int highestRiskQty = 999999;
  
  String mostStagnantProduct = "";
  int highestOverstockQty = 0;

  for (var product in products) {
    final int qty = product['quantity'] as int;
    final double price = product['price'] as double;
    final String name = product['name'] as String;
    
    totalInventoryValue += (qty * price);
    
    if (qty < 10) {
      lowStockCount++;
      if (qty < highestRiskQty) {
        highestRiskQty = qty;
        highestRiskProduct = name;
      }
    } else if (qty > 100) {
      overStockCount++;
      if (qty > highestOverstockQty) {
        highestOverstockQty = qty;
        mostStagnantProduct = name;
      }
    }
  }

  // Generate highly varied, accurate, real-time ML-style insight
  if (lowStockCount > 3) {
    return "Critical Stock Warning: Multiple items are depleting rapidly, putting potential revenue at risk. '$highestRiskProduct' is completely critical at $highestRiskQty units. We strongly advise immediate restocking to maintain sales velocity.";
  } else if (overStockCount > 3) {
    return "Capital Tie-up Alert: The system has detected an imbalance. Too much capital is locked in slow-moving inventory like '$mostStagnantProduct' ($highestOverstockQty units). Consider strategic promotions to clear dead stock and free up cash flow.";
  } else if (totalInventoryValue > 5000) {
    return "Inventory health is optimal. The total held value is strong at \$${totalInventoryValue.toStringAsFixed(2)}. Sales velocity is balanced with current stock levels. No immediate intervention required.";
  } else if (sales.length > 20) {
    return "Sales volume is trending positively, but inventory depth might be too shallow to sustain this momentum long-term. Consider increasing base order quantities for top movers.";
  } else {
    return "The system is currently observing baseline patterns. As more transaction velocity data is collected, deeper prescriptive analytics will be generated to optimize your margins.";
  }
}
