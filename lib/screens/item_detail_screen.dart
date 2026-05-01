import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../services/item_service.dart';
import '../services/auth_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  const ItemDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Item _item;
  final ItemService _itemService = ItemService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showQR = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _itemService.getItemHistory(_item.itemId);
      if (mounted) setState(() => _history = history);
    } catch (e) {}
  }

  Future<void> _toggleStatus() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Необходимо войти в систему'), backgroundColor: Colors.grey[700]),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newStatus = _item.status == ItemStatus.available ? ItemStatus.occupied : ItemStatus.available;
      await _itemService.updateItemStatus(_item.itemId, newStatus, userId: newStatus == ItemStatus.occupied ? currentUser.id : null);
      await _itemService.loadItems();
      final updatedItem = _itemService.getItemById(_item.itemId);
      if (updatedItem != null) setState(() => _item = updatedItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Статус изменен на "${newStatus.displayName}"'), backgroundColor: Colors.grey[600]),
        );
      }
      await _loadHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.grey[700]),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF424242),
        title: Text(_item.name, style: const TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_item.imageUrl.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Image.network(_item.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            const SizedBox(height: 16),
            Container(
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
                        child: Text(_item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Color(0xFF424242))),
                      ),
                      if (_item.price != null)
                        Text('\$${_item.price!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Color(0xFF424242))),
                    ],
                  ),
                  if (_item.category != null) ...[
                    const SizedBox(height: 8),
                    Text(_item.category!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  const SizedBox(height: 12),
                  Text(_item.description, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Text(
                      _item.status.displayName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _showQR = !_showQR),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('QR-код', style: TextStyle(fontSize: 14, color: Color(0xFF424242))),
                    Text(_showQR ? 'Скрыть' : 'Показать', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
            if (_showQR) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Center(
                  child: QrImageView(
                    data: _item.qrData ?? _item.generateQRData(),
                    version: QrVersions.auto,
                    size: 160,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('История', style: TextStyle(fontSize: 14, color: Color(0xFF424242))),
                    const SizedBox(height: 12),
                    ..._history.map((record) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(record['action'], style: const TextStyle(fontSize: 13, color: Color(0xFF424242))),
                          Text(
                            '${record['user']} • ${DateFormat('dd.MM.yyyy HH:mm').format(record['date'])}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF424242),
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    ),
                    child: const Text('Назад', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _toggleStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF616161),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                      _item.status == ItemStatus.available ? 'Взять' : 'Вернуть',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}