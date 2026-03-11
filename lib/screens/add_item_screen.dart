import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../services/item_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String? _generatedQRData;
  bool _isLoading = false;
  int _currentStep = 0;

  final List<String> _categories = [
    'Электроника',
    'Смартфоны',
    'Аудио',
    'Книги',
    'Спорт',
    'Одежда',
    'Другое',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _generateItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newItem = Item(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? ''
            : _imageUrlController.text.trim(),
        status: ItemStatus.available,
        price: double.tryParse(_priceController.text),
        category: _categoryController.text.trim().isEmpty
            ? 'Другое'
            : _categoryController.text.trim(),
        createdAt: DateTime.now(),
      );

      _generatedQRData = newItem.generateQRData();
      await ItemService().addItem(newItem);

      setState(() {
        _isLoading = false;
        _currentStep = 1;
      });
    }
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _categoryController.clear();
    _imageUrlController.clear();
    setState(() {
      _generatedQRData = null;
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить товар'),
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: _currentStep == 0
              ? _buildFormStep()
              : _buildQRStep(),
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Шаг 1 из 2: Введите данные',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Информация о товаре',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Заполните поля для создания товара',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Название товара *',
                    prefixIcon: Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey.shade600),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите название товара';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Описание *',
                    prefixIcon: Icon(Icons.description_outlined, size: 20, color: Colors.grey.shade600),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите описание товара';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Цена',
                    prefixIcon: Icon(Icons.attach_money_outlined, size: 20, color: Colors.grey.shade600),
                    hintText: 'Необязательно',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Категория',
                    prefixIcon: Icon(Icons.category_outlined, size: 20, color: Colors.grey.shade600),
                  ),
                  value: _categoryController.text.isEmpty ? null : _categoryController.text,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoryController.text = value ?? '';
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'URL изображения',
                    prefixIcon: Icon(Icons.image_outlined, size: 20, color: Colors.grey.shade600),
                    hintText: 'Необязательно',
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateItem,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.grey.shade800,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Создать QR-код'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRStep() {
    if (_generatedQRData == null) {
      return const Center(child: Text('Ошибка генерации QR-кода'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Шаг 2 из 2: QR-код готов',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 40,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Товар успешно создан!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w300,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _nameController.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: _generatedQRData!,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'QR-код товара',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildInfoRow('Название', _nameController.text),
                const Divider(height: 16),
                _buildInfoRow('Описание', _descriptionController.text),
                if (_priceController.text.isNotEmpty) ...[
                  const Divider(height: 16),
                  _buildInfoRow('Цена', '\$${_priceController.text}'),
                ],
                if (_categoryController.text.isNotEmpty) ...[
                  const Divider(height: 16),
                  _buildInfoRow('Категория', _categoryController.text),
                ],
                const Divider(height: 16),
                _buildInfoRow(
                  'Дата создания',
                  DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Добавить еще'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Готово'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}