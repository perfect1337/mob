import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory_app.db');
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT UNIQUE NOT NULL, password TEXT NOT NULL, role TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, itemId TEXT UNIQUE NOT NULL, name TEXT NOT NULL, description TEXT NOT NULL, imageUrl TEXT, status TEXT NOT NULL, price REAL, category TEXT, createdAt TEXT NOT NULL, qrData TEXT, createdBy INTEGER, takenBy INTEGER, takenAt TEXT, returnedAt TEXT)''');
    await db.execute('''CREATE TABLE history(id INTEGER PRIMARY KEY AUTOINCREMENT, itemId TEXT NOT NULL, action TEXT NOT NULL, user TEXT NOT NULL, date TEXT NOT NULL)''');
    await db.insert('users', {'email': 'admin@example.com', 'password': 'admin123', 'role': UserRole.admin.toString()});
    await db.insert('users', {'email': 'user@example.com', 'password': 'user123', 'role': UserRole.user.toString()});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''CREATE TABLE IF NOT EXISTS history(id INTEGER PRIMARY KEY AUTOINCREMENT, itemId TEXT NOT NULL, action TEXT NOT NULL, user TEXT NOT NULL, date TEXT NOT NULL)''');
    }
  }

  Future<int> insertUser(User user) async => (await database).insert('users', {'email': user.email, 'password': user.password, 'role': user.role.toString()});
  Future<User?> getUser(String email, String password) async => _firstOrNull(await (await database).query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]), User.fromJson);
  Future<User?> getUserById(int id) async => _firstOrNull(await (await database).query('users', where: 'id = ?', whereArgs: [id]), User.fromJson);
  Future<bool> emailExists(String email) async => (await (await database).query('users', where: 'email = ?', whereArgs: [email])).isNotEmpty;
  Future<List<User>> getAllUsers() async => (await (await database).query('users')).map((m) => User.fromJson(m)).toList();

  Future<int> insertItem(Item item) async => (await database).insert('items', _itemToMap(item));
  Future<List<Item>> getAllItems() async => (await (await database).query('items')).map((m) => Item.fromJson(m)).toList();
  Future<Item?> getItemByItemId(String itemId) async => _firstOrNull(await (await database).query('items', where: 'itemId = ?', whereArgs: [itemId]), Item.fromJson);
  Future<Item?> getItemByQRData(String qrData) async => _firstOrNull(await (await database).query('items', where: 'qrData = ?', whereArgs: [qrData]), Item.fromJson);

  Future<int> updateItemStatus(String itemId, ItemStatus newStatus, {int? userId}) async {
    final item = await getItemByItemId(itemId);
    if (item == null) return 0;
    final now = DateTime.now();
    return await (await database).update('items', {
      'status': newStatus.toString(), 'takenBy': newStatus == ItemStatus.occupied ? userId : null,
      'takenAt': newStatus == ItemStatus.occupied ? now.toIso8601String() : item.takenAt?.toIso8601String(),
      'returnedAt': newStatus == ItemStatus.available ? now.toIso8601String() : item.returnedAt?.toIso8601String(),
    }, where: 'itemId = ?', whereArgs: [itemId]);
  }

  Future<int> deleteItem(String itemId) async => (await database).delete('items', where: 'itemId = ?', whereArgs: [itemId]);

  Future<void> addHistoryRecord(Map<String, dynamic> r) async => (await database).insert('history', {'itemId': r['itemId'], 'action': r['action'], 'user': r['user'], 'date': (r['date'] as DateTime).toIso8601String()});

  Future<List<Map<String, dynamic>>> getItemHistoryFromDB(String itemId) async =>
      (await (await database).query('history', where: 'itemId = ?', whereArgs: [itemId], orderBy: 'date DESC')).map((m) => {'action': m['action'], 'user': m['user'], 'date': DateTime.parse(m['date'] as String)}).toList();

  Map<String, dynamic> _itemToMap(Item item) => {
    'itemId': item.itemId, 'name': item.name, 'description': item.description,
    'imageUrl': item.imageUrl, 'status': item.status.toString(), 'price': item.price,
    'category': item.category, 'createdAt': item.createdAt.toIso8601String(),
    'qrData': item.qrData ?? item.generateQRData(), 'createdBy': item.createdBy,
    'takenBy': item.takenBy, 'takenAt': item.takenAt?.toIso8601String(),
    'returnedAt': item.returnedAt?.toIso8601String(),
  };

  T? _firstOrNull<T>(List<Map<String, dynamic>> maps, T Function(Map<String, dynamic>) fromJson) => maps.isNotEmpty ? fromJson(maps.first) : null;
}