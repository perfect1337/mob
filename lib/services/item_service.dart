import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'database_service.dart';
import 'auth_service.dart';

class ItemService {
  static final ItemService _instance = ItemService._internal();
  factory ItemService() => _instance;
  ItemService._internal();

  List<Item> _items = [];
  final _db = DatabaseService();
  final _firestore = FirebaseFirestore.instance;

  List<Item> get items => _items;

  Future<void> initialize() async => await loadItems();

  Future<void> loadItems() async {
    try {
      final snapshot = await _firestore.collection('items').orderBy('createdAt', descending: true).get();
      _items = snapshot.docs.map((doc) => _itemFromFirestore(doc.data())).toList();
    } catch (_) {
      _items = await _db.getAllItems();
    }
  }

  Future<void> addItem(Item item) async {
    await _firestore.collection('items').doc(item.itemId).set({
      'itemId': item.itemId, 'name': item.name, 'description': item.description,
      'imageUrl': item.imageUrl, 'status': item.status.toString(), 'price': item.price,
      'category': item.category, 'createdAt': item.createdAt.toIso8601String(),
      'qrData': item.qrData ?? item.generateQRData(), 'createdBy': item.createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addHistory(item.itemId, 'Создание');
    await _db.insertItem(item);
    await loadItems();
  }

  Future<void> updateItemStatus(String itemId, ItemStatus newStatus, {int? userId}) async {
    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{'status': newStatus.toString(), 'updatedAt': FieldValue.serverTimestamp()};
    final action = newStatus == ItemStatus.occupied ? 'Взятие' : 'Возврат';
    if (newStatus == ItemStatus.occupied) { updates['takenBy'] = userId; updates['takenAt'] = now; }
    else { updates['takenBy'] = null; updates['returnedAt'] = now; }

    await _firestore.collection('items').doc(itemId).update(updates);
    await _addHistory(itemId, action);
    await _db.updateItemStatus(itemId, newStatus, userId: userId);
    await loadItems();
  }

  Item? getItemById(String itemId) => _items.cast<Item?>().firstWhere((i) => i?.itemId == itemId, orElse: () => null);
  List<Item> getItemsByStatus(ItemStatus s) => _items.where((i) => i.status == s).toList();
  List<String> getCategories() => _items.map((i) => i.category ?? 'Другое').toSet().toList();

  Future<Item?> findItemByQRData(String qrData) async {
    try {
      final snapshot = await _firestore.collection('items').where('qrData', isEqualTo: qrData).get();
      if (snapshot.docs.isNotEmpty) return _itemFromFirestore(snapshot.docs.first.data());
    } catch (_) {}
    return await _db.getItemByQRData(qrData);
  }

  Future<List<Map<String, dynamic>>> getItemHistory(String itemId) async {
    try {
      final snapshot = await _firestore.collection('history').where('itemId', isEqualTo: itemId).get();
      final history = snapshot.docs.map((doc) {
        final d = doc.data();
        return {'action': d['action'] ?? '', 'user': d['user'] ?? '', 'date': (d['timestamp'] as Timestamp).toDate()};
      }).toList();
      history.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      return history;
    } catch (_) {
      return await _db.getItemHistoryFromDB(itemId);
    }
  }

  Future<void> _addHistory(String itemId, String action) async {
    final user = AuthService().currentUser?.email ?? 'Система';
    await _firestore.collection('history').add({'itemId': itemId, 'action': action, 'user': user, 'timestamp': FieldValue.serverTimestamp()});
    await _db.addHistoryRecord({'itemId': itemId, 'action': action, 'user': user, 'date': DateTime.now()});
  }

  Item _itemFromFirestore(Map<String, dynamic> d) => Item(
    itemId: d['itemId'] ?? '', name: d['name'] ?? '', description: d['description'] ?? '',
    imageUrl: d['imageUrl'] ?? '', status: d['status'] == 'ItemStatus.occupied' ? ItemStatus.occupied : ItemStatus.available,
    price: d['price']?.toDouble(), category: d['category'],
    createdAt: DateTime.tryParse(d['createdAt'] ?? '') ?? DateTime.now(),
    qrData: d['qrData'], createdBy: d['createdBy'], takenBy: d['takenBy'],
    takenAt: d['takenAt'] != null ? DateTime.tryParse(d['takenAt']) : null,
    returnedAt: d['returnedAt'] != null ? DateTime.tryParse(d['returnedAt']) : null,
  );
}