import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/qr_display.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  const ItemDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Item _item;
  bool _showQR = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await Provider.of<ItemProvider>(context, listen: false).getItemHistory(_item.itemId);
    if (mounted) setState(() => _history = history);
  }

  Future<void> _toggleStatus(ItemProvider itemProvider, AuthProvider authProvider) async {
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Необходимо войти в систему'), backgroundColor: Colors.grey[700]));
      return;
    }

    final newStatus = _item.status == ItemStatus.available ? ItemStatus.occupied : ItemStatus.available;
    await itemProvider.updateItemStatus(_item.itemId, newStatus);

    final updatedItem = itemProvider.getItemById(_item.itemId);
    if (updatedItem != null) setState(() => _item = updatedItem);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Статус изменен на "${newStatus.displayName}"'), backgroundColor: Colors.grey[600]));
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ItemProvider, AuthProvider>(
      builder: (context, itemProvider, authProvider, child) {
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
                          Expanded(child: Text(_item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Color(0xFF424242)))),
                          if (_item.price != null) Text('\$${_item.price!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Color(0xFF424242))),
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
                        child: Text(_item.status.displayName, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
                  QRDisplay(data: _item.qrData ?? _item.generateQRData()),
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
                              Text('${record['user']} • ${DateFormat('dd.MM.yyyy HH:mm').format(record['date'])}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
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
                    Expanded(child: CustomButton(onPressed: () => Navigator.pop(context), text: 'Назад', isOutlined: true)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        onPressed: () => _toggleStatus(itemProvider, authProvider),
                        text: _item.status == ItemStatus.available ? 'Взять' : 'Вернуть',
                        isLoading: itemProvider.isLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}