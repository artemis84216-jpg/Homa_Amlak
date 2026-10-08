import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('homa_amlak.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL, type TEXT, area REAL, price REAL, address TEXT,
        owner_name TEXT, owner_phone TEXT,
        status TEXT DEFAULT 'available', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, national_id TEXT, phone TEXT, role TEXT, notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE contracts (id INTEGER PRIMARY KEY AUTOINCREMENT, property_id INTEGER, customer_id INTEGER, type TEXT, start_date TEXT, end_date TEXT, amount REAL, status TEXT DEFAULT "active", notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE payments (id INTEGER PRIMARY KEY AUTOINCREMENT, contract_id INTEGER, amount REAL, date TEXT, type TEXT, description TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, amount REAL, date TEXT, description TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE agents (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, national_id TEXT, commission_rate REAL DEFAULT 0.0, base_salary REAL DEFAULT 0.0, status TEXT DEFAULT "active", join_date TEXT, notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE properties ADD COLUMN owner_name TEXT');
      await db.execute('ALTER TABLE properties ADD COLUMN owner_phone TEXT');
    }
  }

  // --- توابع املاک ---
  Future<int> insertProperty(Map<String, dynamic> property) async {
    final db = await instance.database;
    return await db.insert('properties', property);
  }

  Future<List<Map<String, dynamic>>> getAllProperties() async {
    final db = await instance.database;
    return await db.query('properties', orderBy: 'id DESC');
  }

  Future<Map<String, dynamic>?> getPropertyById(int id) async {
    final db = await instance.database;
    final result = await db.query('properties', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateProperty(int id, Map<String, dynamic> property) async {
    final db = await instance.database;
    return await db.update('properties', property, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProperty(int id) async {
    final db = await instance.database;
    return await db.delete('properties', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> searchProperties(String query) async {
    final db = await instance.database;
    return await db.query(
      'properties',
      where: 'title LIKE ? OR type LIKE ? OR address LIKE ? OR owner_name LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'id DESC',
    );
  }

  // --- توابع مشتریان ---
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await instance.database;
    return await db.query('customers', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final db = await instance.database;
    return await db.query(
      'customers',
      where: 'name LIKE ? OR national_id LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'id DESC',
    );
  }

  // --- توابع قراردادها ---
  Future<int> insertContract(Map<String, dynamic> contract) async {
    final db = await instance.database;
    return await db.insert('contracts', contract);
  }

  Future<List<Map<String, dynamic>>> getAllContracts() async {
    final db = await instance.database;
    return await db.query('contracts', orderBy: 'id DESC');
  }

  // --- توابع پرداخت‌ها ---
  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await instance.database;
    return await db.insert('payments', payment);
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final db = await instance.database;
    return await db.query('payments', orderBy: 'id DESC');
  }

  // --- توابع هزینه‌ها ---
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await instance.database;
    return await db.query('expenses', orderBy: 'id DESC');
  }

  // --- توابع مشاوران ---
  Future<int> insertAgent(Map<String, dynamic> agent) async {
    final db = await instance.database;
    return await db.insert('agents', agent);
  }

  Future<List<Map<String, dynamic>>> getAllAgents() async {
    final db = await instance.database;
    return await db.query('agents', orderBy: 'id DESC');
  }
}
