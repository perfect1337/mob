import 'dart:convert';
import 'package:flutter/material.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final ItemStatus status;
  final double? price;
  final String? category;
  final DateTime createdAt;
  final String? qrData;
  
  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.status,
    this.price,
    this.category,
    required this.createdAt,
    this.qrData,
  });

  String generateQRData() {
    final data = {
      'id': id,
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
        id: json['id'] as String,
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
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'status': status.toString(),
      'price': price,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'qrData': qrData ?? generateQRData(),
    };
  }

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
      createdAt: DateTime.parse(json['createdAt'] as String),
      qrData: json['qrData'] as String?,
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
        return const Color(0xFF9E9E9E);
      case ItemStatus.occupied:
        return const Color(0xFFBDBDBD);
    }
  }
}