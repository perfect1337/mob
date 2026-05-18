import 'package:flutter/material.dart';
import '../services/item_service.dart';
import '../services/auth_service.dart';
import '../models/item.dart';

class ItemProvider extends ChangeNotifier {
  final ItemService _itemService = ItemService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  ItemProvider() {
    _init();
  }

  Future<void> _init() async {
    await _itemService.initialize();
    notifyListeners();
  }

  List<Item> get items => _itemService.items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Item> getAvailableItems() => _itemService.getItemsByStatus(ItemStatus.available);
  List<Item> getOccupiedItems() => _itemService.getItemsByStatus(ItemStatus.occupied);

  List<String> getCategories() => _itemService.getCategories();

  List<Item> getFilteredItems({String? category, String? searchQuery}) {
    var filtered = _itemService.items;
    if (category != null && category != 'Все') {
      filtered = filtered.where((item) => item.category == category).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
      item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    return filtered;
  }

  Future<void> addItem(Item item) async {
    _setLoading(true);
    _clearError();
    try {
      await _itemService.addItem(item);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка при добавлении товара');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateItemStatus(String itemId, ItemStatus newStatus) async {
    _setLoading(true);
    _clearError();
    try {
      final userId = _authService.currentUser?.id;
      await _itemService.updateItemStatus(itemId, newStatus, userId: userId);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка при изменении статуса');
    } finally {
      _setLoading(false);
    }
  }

  Item? getItemById(String itemId) => _itemService.getItemById(itemId);

  Future<Item?> findItemByQRData(String qrData) async => await _itemService.findItemByQRData(qrData);

  Future<List<Map<String, dynamic>>> getItemHistory(String itemId) async => await _itemService.getItemHistory(itemId);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}