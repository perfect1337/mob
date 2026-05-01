import 'dart:convert';

enum ItemStatus {
  available,
  occupied;

  String get displayName {
    switch (this) {
      case ItemStatus.available:
        return 'Свободен';
      case ItemStatus.occupied:
        return 'Занят';
    }
  }
}

class Item {
  final int? id;
  final String itemId;
  final String name;
  final String description;
  final String imageUrl;
  final ItemStatus status;
  final double? price;
  final String? category;
  final DateTime createdAt;
  final String? qrData;
  final int? createdBy;
  final int? takenBy;
  final DateTime? takenAt;
  final DateTime? returnedAt;

  Item({
    this.id,
    required this.itemId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.status,
    this.price,
    this.category,
    required this.createdAt,
    this.qrData,
    this.createdBy,
    this.takenBy,
    this.takenAt,
    this.returnedAt,
  });

  String generateQRData() {
    final data = {
      'itemId': itemId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
    return jsonEncode(data);
  }

  static Item? fromQRData(String qrData) {
    try {
      final Map<String, dynamic> json = jsonDecode(qrData);
      return Item(
        itemId: json['itemId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        imageUrl: '',
        status: ItemStatus.available,
        price: json['price'] != null ? (json['price'] as num).toDouble() : null,
        category: json['category'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        qrData: qrData,
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'status': status.toString(),
      'price': price,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'qrData': qrData ?? generateQRData(),
      'createdBy': createdBy,
      'takenBy': takenBy,
      'takenAt': takenAt?.toIso8601String(),
      'returnedAt': returnedAt?.toIso8601String(),
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int?,
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      price: json['price'] as double?,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      qrData: json['qrData'] as String?,
      createdBy: json['createdBy'] as int?,
      takenBy: json['takenBy'] as int?,
      takenAt: json['takenAt'] != null
          ? DateTime.parse(json['takenAt'] as String)
          : null,
      returnedAt: json['returnedAt'] != null
          ? DateTime.parse(json['returnedAt'] as String)
          : null,
    );
  }

  static ItemStatus _parseStatus(String? status) {
    if (status == null) return ItemStatus.available;
    if (status.contains('available')) return ItemStatus.available;
    if (status.contains('occupied')) return ItemStatus.occupied;
    return ItemStatus.available;
  }

  @override
  String toString() {
    return 'Item(id: $id, itemId: $itemId, name: $name, status: $status)';
  }
}