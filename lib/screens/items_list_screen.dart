import 'package:flutter/material.dart';
import '../services/item_service.dart';
import '../services/auth_service.dart';
import '../models/item.dart';
import '../models/user.dart';
import 'item_detail_screen.dart';
import 'add_item_screen.dart';
import 'scan_qr_screen.dart';
import 'dart:convert';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({Key? key}) : super(key: key);

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final ItemService _itemService = ItemService();
  final AuthService _authService = AuthService();
  String _selectedCategory = 'Все';
  List<String> _categories = ['Все'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategories() {
    final categories = _itemService.getCategories();
    setState(() => _categories = ['Все', ...categories]);
  }

  List<Item> _getFilteredItems() {
    var items = _itemService.items;
    if (_selectedCategory != 'Все') {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) =>
      item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    return items;
  }

  Future<void> _handleScanResult(dynamic result) async {
    if (result == null || !mounted) return;
    Item? itemToShow;

    if (result is Item) {
      itemToShow = result;
    } else if (result is String) {
      itemToShow = _itemService.getItemById(result);
      if (itemToShow == null) {
        itemToShow = await _itemService.findItemByQRData(result);
      }
      if (itemToShow == null && result.startsWith('{')) {
        try {
          final jsonData = jsonDecode(result);
          itemToShow = Item(
            itemId: jsonData['itemId'] as String? ?? jsonData['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: jsonData['name'] as String? ?? 'Товар из QR-кода',
            description: jsonData['description'] as String? ?? 'Нет описания',
            imageUrl: jsonData['imageUrl'] as String? ?? '',
            status: ItemStatus.available,
            price: jsonData['price'] != null ? (jsonData['price'] as num).toDouble() : null,
            category: jsonData['category'] as String?,
            createdAt: jsonData['createdAt'] != null ? DateTime.parse(jsonData['createdAt'] as String) : DateTime.now(),
            qrData: result,
          );
        } catch (e) {}
      }
    }

    if (itemToShow != null && mounted) {
      final currentUser = _authService.currentUser;
      if (itemToShow.status == ItemStatus.available) {
        if (currentUser != null && currentUser.canChangeItemStatus) {
          await _itemService.updateItemStatus(itemToShow.itemId, ItemStatus.occupied, userId: currentUser.id);
          await _itemService.loadItems();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Товар "${itemToShow.name}" взят'), backgroundColor: Colors.grey[700]),
            );
          }
          final updatedItem = _itemService.getItemById(itemToShow.itemId);
          if (updatedItem != null) itemToShow = updatedItem;
        }
      } else {
        if (currentUser != null && currentUser.canChangeItemStatus) {
          await _itemService.updateItemStatus(itemToShow.itemId, ItemStatus.available);
          await _itemService.loadItems();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Товар "${itemToShow.name}" возвращен'), backgroundColor: Colors.grey[600]),
            );
          }
          final updatedItem = _itemService.getItemById(itemToShow.itemId);
          if (updatedItem != null) itemToShow = updatedItem;
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ItemDetailScreen(item: itemToShow!)),
          ).then((_) => setState(() {}));
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось распознать QR-код'), backgroundColor: Colors.grey[700]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();
    final currentUser = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'КАТАЛОГ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanQrScreen()),
                      );
                      await _handleScanResult(result);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                    child: const Text('QR', style: TextStyle(fontSize: 13)),
                  ),
                  if (currentUser != null && currentUser.canCreateItems)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddItemScreen()),
                        ).then((_) => setState(() {}));
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                      child: const Text('Добавить', style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Поиск...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(2),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(2),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(2),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                          ),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = category == _selectedCategory;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: TextButton(
                                  onPressed: () => setState(() => _selectedCategory = category),
                                  style: TextButton.styleFrom(
                                    backgroundColor: isSelected ? const Color(0xFF424242) : Colors.grey[100],
                                    foregroundColor: isSelected ? Colors.white : const Color(0xFF616161),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  child: Text(category),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${filteredItems.length} товаров',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Свободно: ${_itemService.getItemsByStatus(ItemStatus.available).length}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Занято: ${_itemService.getItemsByStatus(ItemStatus.occupied).length}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Товары не найдены', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
                          const SizedBox(height: 8),
                          Text('Измените параметры поиска', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) => _buildItemCard(filteredItems[index]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)),
        ).then((_) => setState(() {}));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF424242)),
                  ),
                ),
                Text(
                  item.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.status == ItemStatus.available ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.category != null) ...[
              const SizedBox(height: 8),
              Text(item.category!, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
            if (item.price != null) ...[
              const SizedBox(height: 4),
              Text(
                '\$${item.price!.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}