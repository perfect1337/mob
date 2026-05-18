import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/category_filter.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';
import 'add_item_screen.dart';
import 'scan_qr_screen.dart';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({Key? key}) : super(key: key);

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  String _selectedCategory = 'Все';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleScanResult(dynamic result, BuildContext context, ItemProvider itemProvider, AuthProvider authProvider) async {
    if (result == null || !mounted) return;
    Item? itemToShow;

    if (result is Item) {
      itemToShow = result;
    } else if (result is String) {
      itemToShow = itemProvider.getItemById(result);
      if (itemToShow == null) {
        itemToShow = await itemProvider.findItemByQRData(result);
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
      final currentUser = authProvider.currentUser;
      if (itemToShow.status == ItemStatus.available) {
        if (currentUser != null && currentUser.canChangeItemStatus) {
          await itemProvider.updateItemStatus(itemToShow.itemId, ItemStatus.occupied);
          final updatedItem = itemProvider.getItemById(itemToShow.itemId);
          if (updatedItem != null) itemToShow = updatedItem;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Товар "${itemToShow.name}" взят'), backgroundColor: Colors.grey[700]));
        }
      } else {
        if (currentUser != null && currentUser.canChangeItemStatus) {
          await itemProvider.updateItemStatus(itemToShow.itemId, ItemStatus.available);
          final updatedItem = itemProvider.getItemById(itemToShow.itemId);
          if (updatedItem != null) itemToShow = updatedItem;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Товар "${itemToShow.name}" возвращен'), backgroundColor: Colors.grey[600]));
        }
      }

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailScreen(item: itemToShow!))).then((_) => setState(() {}));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось распознать QR-код'), backgroundColor: Colors.grey[700]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ItemProvider, AuthProvider>(
      builder: (context, itemProvider, authProvider, child) {
        final categories = ['Все', ...itemProvider.getCategories()];
        final filteredItems = itemProvider.getFilteredItems(category: _selectedCategory, searchQuery: _searchQuery);
        final currentUser = authProvider.currentUser;

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
                      const Expanded(child: Text('КАТАЛОГ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: Color(0xFF424242)))),
                      TextButton(
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanQrScreen()));
                          await _handleScanResult(result, context, itemProvider, authProvider);
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                        child: const Text('QR', style: TextStyle(fontSize: 13)),
                      ),
                      if (currentUser != null && currentUser.canCreateItems)
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen())).then((_) => setState(() {}));
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
                            CustomTextField(
                              controller: _searchController,
                              hintText: 'Поиск...',
                              onChanged: (value) => setState(() => _searchQuery = value ?? ''),
                            ),
                            const SizedBox(height: 12),
                            CategoryFilter(
                              categories: categories,
                              selectedCategory: _selectedCategory,
                              onCategorySelected: (category) => setState(() => _selectedCategory = category),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('${filteredItems.length} товаров', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                const SizedBox(width: 16),
                                Text('Свободно: ${itemProvider.getAvailableItems().length}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                const SizedBox(width: 16),
                                Text('Занято: ${itemProvider.getOccupiedItems().length}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: itemProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filteredItems.isEmpty
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
                          itemBuilder: (context, index) => ItemCard(
                            item: filteredItems[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ItemDetailScreen(item: filteredItems[index])),
                              ).then((_) => setState(() {}));
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}