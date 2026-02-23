import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class ItemService {
  static final ItemService _instance = ItemService._internal();
  factory ItemService() => _instance;
  ItemService._internal();

  List<Item> _items = [];
  
  static const String _itemsKey = 'items';

  List<Item> get items => _items;

  Future<void> initialize() async {
    await _loadItems();

    if (_items.isEmpty) {
      await _addSampleItems();
    }
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString(_itemsKey);
    
    if (itemsJson != null) {
      final List<dynamic> itemsList = jsonDecode(itemsJson);
      _items = itemsList
          .map((json) => Item.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> itemsJson =
        _items.map((item) => item.toJson()).toList();
    await prefs.setString(_itemsKey, jsonEncode(itemsJson));
  }

  Future<void> _addSampleItems() async {
    _items = [
      Item(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '1',
        name: 'Ноутбук Dell XPS 15',
        description: 'Мощный ноутбук для работы и игр. Процессор Intel Core i7, 16GB RAM, 512GB SSD.',
        imageUrl: 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        status: ItemStatus.available,
        price: 899.99,
        category: 'Электроника',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Item(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '2',
        name: 'iPhone 13 Pro',
        description: 'Смартфон Apple с камерой профессионального уровня. 128GB.',
        imageUrl: 'https://images.unsplash.com/photo-1632661674596-df8be8a3a2fa?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        status: ItemStatus.available,
        price: 799.99,
        category: 'Смартфоны',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
    
    await _saveItems();
  }

  Future<void> addItem(Item item) async {
    _items.add(item);
    await _saveItems();
  }


  Future<bool> deleteItem(String id) async {
    try {
      _items.removeWhere((item) => item.id == id);
      await _saveItems();
      return true;
    } catch (e) {
      return false;
    }
  }

  Item? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Обновление статуса товара
  Future<void> updateItemStatus(String id, ItemStatus newStatus) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final oldItem = _items[index];
      _items[index] = Item(
        id: oldItem.id,
        name: oldItem.name,
        description: oldItem.description,
        imageUrl: oldItem.imageUrl,
        status: newStatus,
        price: oldItem.price,
        category: oldItem.category,
        createdAt: oldItem.createdAt,
        qrData: oldItem.qrData,
      );
      await _saveItems();
    }
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

  Item? findItemByQRData(String qrData) {
    try {
      return _items.firstWhere((item) => item.qrData == qrData);
    } catch (e) {
      return null;
    }
  }
}