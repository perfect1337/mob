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
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'inventory_app.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemId TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        imageUrl TEXT,
        status TEXT NOT NULL,
        price REAL,
        category TEXT,
        createdAt TEXT NOT NULL,
        qrData TEXT,
        createdBy INTEGER,
        takenBy INTEGER,
        takenAt TEXT,
        returnedAt TEXT
      )
    ''');


    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {

    await db.insert('users', {
      'email': 'admin@example.com',
      'password': 'admin123',
      'role': UserRole.admin.toString(),
    });

    await db.insert('users', {
      'email': 'user@example.com',
      'password': 'user123',
      'role': UserRole.user.toString(),
    });
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', {
      'email': user.email,
      'password': user.password,
      'role': user.role.toString(),
    });
  }

  Future<User?> getUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromJson(maps[i]));
  }

  Future<int> insertItem(Item item) async {
    final db = await database;
    return await db.insert('items', {
      'itemId': item.itemId,
      'name': item.name,
      'description': item.description,
      'imageUrl': item.imageUrl,
      'status': item.status.toString(),
      'price': item.price,
      'category': item.category,
      'createdAt': item.createdAt.toIso8601String(),
      'qrData': item.qrData ?? item.generateQRData(),
      'createdBy': item.createdBy,
      'takenBy': item.takenBy,
      'takenAt': item.takenAt?.toIso8601String(),
      'returnedAt': item.returnedAt?.toIso8601String(),
    });
  }

  Future<List<Item>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('items');
    return List.generate(maps.length, (i) => Item.fromJson(maps[i]));
  }

  Future<Item?> getItemByItemId(String itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'itemId = ?',
      whereArgs: [itemId],
    );

    if (maps.isNotEmpty) {
      return Item.fromJson(maps.first);
    }
    return null;
  }

  Future<Item?> getItemByQRData(String qrData) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'qrData = ?',
      whereArgs: [qrData],
    );

    if (maps.isNotEmpty) {
      return Item.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    return await db.update(
      'items',
      {
        'name': item.name,
        'description': item.description,
        'imageUrl': item.imageUrl,
        'status': item.status.toString(),
        'price': item.price,
        'category': item.category,
        'qrData': item.qrData,
        'takenBy': item.takenBy,
        'takenAt': item.takenAt?.toIso8601String(),
        'returnedAt': item.returnedAt?.toIso8601String(),
      },
      where: 'itemId = ?',
      whereArgs: [item.itemId],
    );
  }

  Future<int> updateItemStatus(String itemId, ItemStatus newStatus, {int? userId}) async {
    final item = await getItemByItemId(itemId);
    if (item == null) return 0;

    final now = DateTime.now();
    final updatedItem = Item(
      itemId: item.itemId,
      name: item.name,
      description: item.description,
      imageUrl: item.imageUrl,
      status: newStatus,
      price: item.price,
      category: item.category,
      createdAt: item.createdAt,
      qrData: item.qrData,
      createdBy: item.createdBy,
      takenBy: newStatus == ItemStatus.occupied ? userId : null,
      takenAt: newStatus == ItemStatus.occupied ? now : item.takenAt,
      returnedAt: newStatus == ItemStatus.available ? now : item.returnedAt,
    );

    return await updateItem(updatedItem);
  }

  Future<int> deleteItem(String itemId) async {
    final db = await database;
    return await db.delete(
      'items',
      where: 'itemId = ?',
      whereArgs: [itemId],
    );
  }

  Future<List<Map<String, dynamic>>> getItemHistory(String itemId) as nc {
    final item = await getItemByItemId(itemId);
    if (item == null) return [];

    List<Map<String, dynamic>> history = [];

    if (item.takenBy != null && item.takenAt != null) {
      final user = await getUserById(item.takenBy!);
      history.add({
        'action': 'Взятие',
        'user': user?.email ?? 'Неизвестный пользователь',
        'date': item.takenAt!,
      });
    }

    if (item.returnedAt != null) {
      history.add({
        'action': 'Возврат',
        'user': 'Пользователь',
        'date': item.returnedAt!,
      });
    }

    return history;
  }
}