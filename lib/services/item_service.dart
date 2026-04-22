import '../models/item.dart';
import 'database_service.dart';

class ItemService {
  static final ItemService _instance = ItemService._internal();
  factory ItemService() => _instance;
  ItemService._internal();

  List<Item> _items = [];
  final DatabaseService _dbService = DatabaseService();

  List<Item> get items => _items;

  Future<void> initialize() async {
    await loadItems();

    if (_items.isEmpty) {
      await _addSampleItems();
    }
  }

  Future<void> loadItems() async {
    _items = await _dbService.getAllItems();
  }

  Future<void> _addSampleItems() async {
    final sampleItems = [
      Item(
        itemId: DateTime.now().millisecondsSinceEpoch.toString() + '1',
        name: 'Ноутбук Dell XPS 15',
        description: 'Мощный ноутбук для работы и игр. Процессор Intel Core i7, 16GB RAM, 512GB SSD.',
        imageUrl: 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        status: ItemStatus.available,
        price: 899.99,
        category: 'Электроника',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Item(
        itemId: DateTime.now().millisecondsSinceEpoch.toString() + '2',
        name: 'iPhone 13 Pro',
        description: 'Смартфон Apple с камерой профессионального уровня. 128GB.',
        imageUrl: 'https://images.unsplash.com/photo-1632661674596-df8be8a3a2fa?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        status: ItemStatus.available,
        price: 799.99,
        category: 'Смартфоны',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    for (var item in sampleItems) {
      await addItem(item);
    }
  }

  Future<void> addItem(Item item) async {
    await _dbService.insertItem(item);
    await loadItems();
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _dbService.deleteItem(itemId);
      await loadItems();
      return true;
    } catch (e) {
      return false;
    }
  }

  Item? getItemById(String itemId) {
    try {
      return _items.firstWhere((item) => item.itemId == itemId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateItemStatus(String itemId, ItemStatus newStatus, {int? userId}) async {
    await _dbService.updateItemStatus(itemId, newStatus, userId: userId);
    await loadItems();
  }

  List<Item> getItemsByStatus(ItemStatus status) {
    return _items.where((item) => item.status == status).toList();
  }

  List<Item> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  List<String> getCategories() {
    return _items.map((item) => item.category ?? 'Другое').toSet().toList();
  }


  Future<Item?> findItemByQRData(String qrData) async {
    try {
      return await _dbService.getItemByQRData(qrData);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getItemHistory(String itemId) async {
    return await _dbService.getItemHistory(itemId);
  }
}