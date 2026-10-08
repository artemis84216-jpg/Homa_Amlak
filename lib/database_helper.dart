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
    return await openDatabase(path, version: 8, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL, type TEXT, area REAL, price REAL, monthly_rent REAL DEFAULT 0, address TEXT,
        owner_name TEXT, owner_phone TEXT,
        agent_name TEXT, agent_phone TEXT,
        bedrooms INTEGER DEFAULT 0, floor INTEGER DEFAULT 0, total_floors INTEGER DEFAULT 0,
        listing_type TEXT DEFAULT 'sale',
        images TEXT, is_public INTEGER DEFAULT 1, status TEXT DEFAULT 'available', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE TABLE customers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, national_id TEXT, phone TEXT, role TEXT, notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE contracts (id INTEGER PRIMARY KEY AUTOINCREMENT, property_id INTEGER, customer_id INTEGER, type TEXT, start_date TEXT, end_date TEXT, amount REAL, status TEXT DEFAULT "active", notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE payments (id INTEGER PRIMARY KEY AUTOINCREMENT, contract_id INTEGER, amount REAL, date TEXT, type TEXT, description TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, amount REAL, date TEXT, description TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute('''
      CREATE TABLE agents (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, national_id TEXT, 
        password TEXT, profile_image TEXT,
        commission_rate REAL DEFAULT 0.0, base_salary REAL DEFAULT 0.0, status TEXT DEFAULT "active", join_date TEXT, notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    // جدول جدید درخواست‌های بازدید
    await db.execute('''
      CREATE TABLE viewings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        viewing_date TEXT NOT NULL,
        viewing_time TEXT NOT NULL,
        notes TEXT,
        status TEXT DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) { await db.execute('ALTER TABLE properties ADD COLUMN owner_name TEXT'); await db.execute('ALTER TABLE properties ADD COLUMN owner_phone TEXT'); }
    if (oldVersion < 3) { await db.execute('ALTER TABLE properties ADD COLUMN images TEXT'); }
    if (oldVersion < 4) { await db.execute('ALTER TABLE properties ADD COLUMN agent_name TEXT'); await db.execute('ALTER TABLE properties ADD COLUMN agent_phone TEXT'); }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE agents ADD COLUMN password TEXT');
      await db.execute('ALTER TABLE agents ADD COLUMN profile_image TEXT');
      await db.execute('ALTER TABLE properties ADD COLUMN is_public INTEGER DEFAULT 1');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE properties ADD COLUMN bedrooms INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE properties ADD COLUMN floor INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE properties ADD COLUMN total_floors INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE properties ADD COLUMN listing_type TEXT DEFAULT "sale"');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE properties ADD COLUMN monthly_rent REAL DEFAULT 0');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE viewings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          property_id INTEGER,
          customer_name TEXT NOT NULL,
          customer_phone TEXT NOT NULL,
          viewing_date TEXT NOT NULL,
          viewing_time TEXT NOT NULL,
          notes TEXT,
          status TEXT DEFAULT 'pending',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
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

  // --- توابع مشاوران ---
  Future<int> insertAgent(Map<String, dynamic> agent) async {
    final db = await instance.database;
    return await db.insert('agents', agent);
  }

  Future<List<Map<String, dynamic>>> getAllAgents() async {
    final db = await instance.database;
    return await db.query('agents', orderBy: 'id DESC');
  }

  Future<Map<String, dynamic>?> getAgentByCredentials(String name, String password) async {
    final db = await instance.database;
    final result = await db.query('agents', where: 'name = ? AND password = ? AND status = "active"', whereArgs: [name, password]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateAgent(int id, Map<String, dynamic> agent) async {
    final db = await instance.database;
    return await db.update('agents', agent, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAgent(int id) async {
    final db = await instance.database;
    return await db.delete('agents', where: 'id = ?', whereArgs: [id]);
  }

  // --- توابع بازدیدها (جدید) ---
  Future<int> insertViewing(Map<String, dynamic> viewing) async {
    final db = await instance.database;
    return await db.insert('viewings', viewing);
  }

  Future<List<Map<String, dynamic>>> getAllViewings() async {
    final db = await instance.database;
    return await db.query('viewings', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getViewingsByAgent(String agentName) async {
    final db = await instance.database;
    // فقط بازدیدهای مربوط به املاک این مشاور را برگردان
    return await db.rawQuery('''
      SELECT v.*, p.title as property_title, p.agent_name 
      FROM viewings v 
      JOIN properties p ON v.property_id = p.id 
      WHERE p.agent_name = ? 
      ORDER BY v.id DESC
    ''', [agentName]);
  }

  Future<int> updateViewingStatus(int id, String status) async {
    final db = await instance.database;
    return await db.update('viewings', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteViewing(int id) async {
    final db = await instance.database;
    return await db.delete('viewings', where: 'id = ?', whereArgs: [id]);
  }
}
