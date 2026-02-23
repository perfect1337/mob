
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

  // Инициализация - загрузка данных из SharedPreferences
  Future<void> initialize() async {
    await _loadItems();
    
    // Если товаров нет, добавляем тестовые данные
    if (_items.isEmpty) {
      await _addSampleItems();
    }
  }

  // Загрузка товаров из SharedPreferences
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

  // Сохранение товаров в SharedPreferences
  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> itemsJson =
        _items.map((item) => item.toJson()).toList();
    await prefs.setString(_itemsKey, jsonEncode(itemsJson));
  }

  // Добавление тестовых товаров
  Future<void> _addSampleItems() async {
    _items = [
      Item(
        id: '1',
        name: 'Ноутбук Dell XPS 15',
        description: 'Мощный ноутбук для работы и игр. Процессор Intel Core i7, 16GB RAM, 512GB SSD, видеокарта NVIDIA GeForce GTX 1650.',
        imageUrl: 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        status: ItemStatus.available,
        price: 899.99,
        category: 'Электроника',
      ),
      Item(
        id: '2',
        name: 'iPhone 13 Pro',
        description: 'Смартфон Apple с камерой профессионального уровня. 128GB, цвет Sierra Blue, отличное состояние.',
        imageUrl: 'https://images.unsplash.com/photo-1632661674596-df8be8a3a2fa?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        status: ItemStatus.available,
        price: 799.99,
        category: 'Смартфоны',
      ),
      Item(
        id: '3',
        name: 'Наушники Sony WH-1000XM4',
        description: 'Беспроводные наушники с шумоподавлением. Отличное качество звука, комфортные амбушюры.',
        imageUrl: 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        status: ItemStatus.occupied,
        price: 249.99,
        category: 'Аудио',
      ),
      Item(
        id: '4',
        name: 'Книга "Flutter в действии"',
        description: 'Практическое руководство по разработке мобильных приложений на Flutter. Состояние новой.',
        imageUrl: 'https://images.unsplash.com/photo-1532012197267-da84d127e765?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        status: ItemStatus.available,
        price: 29.99,
        category: 'Книги',
      ),
      Item(
        id: '5',
        name: 'Велосипед горный',
        description: 'Горный велосипед 26 дюймов, 21 скорость, дисковые тормоза. В отличном состоянии.',
        imageUrl: 'https://images.unsplash.com/photo-1576435728678-68d0fbf94e91?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        status: ItemStatus.available,
        price: 349.99,
        category: 'Спорт',
      ),
      Item(
        id: '6',
        name: 'Фотоаппарат Canon EOS R6',
        description: 'Зеркальный фотоаппарат с 4K видео, комплект с объективом 24-105mm.',
        imageUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        status: ItemStatus.occupied,
        price: 1899.99,
        category: 'Электроника',
      ),
    ];
    
    await _saveItems();
  }

  // Получение товара по ID
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
      );
      await _saveItems();
    }
  }

  // Фильтрация товаров по статусу
  List<Item> getItemsByStatus(ItemStatus status) {
    return _items.where((item) => item.status == status).toList();
  }

  // Фильтрация товаров по категории
  List<Item> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  // Получение всех категорий
  List<String> getCategories() {
    return _items.map((item) => item.category ?? 'Другое').toSet().toList();
  }
}