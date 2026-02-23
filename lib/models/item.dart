import 'dart:ui';

class Item {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final ItemStatus status;
  final double? price;
  final String? category;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.status,
    this.price,
    this.category,
  });

  // Преобразование Item в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'status': status.toString(),
      'price': price,
      'category': category,
    };
  }

  // Создание Item из JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      status: ItemStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ItemStatus.available,
      ),
      price: json['price'] as double?,
      category: json['category'] as String?,
    );
  }

  @override
  String toString() {
    return 'Item(id: $id, name: $name, status: $status)';
  }
}

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

  Color get color {
    switch (this) {
      case ItemStatus.available:
        return Color(0xFF4CAF50); // Зеленый
      case ItemStatus.occupied:
        return Color(0xFFF44336); // Красный
    }
  }
}