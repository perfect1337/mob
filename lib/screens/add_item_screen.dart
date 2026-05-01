import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import '../services/item_service.dart';
import '../services/auth_service.dart';

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

  File? _selectedImage;
  String? _generatedQRData;
  bool _isLoading = false;
  int _currentStep = 0;

  final List<String> _categories = [
    'Электроника', 'Смартфоны', 'Аудио', 'Книги', 'Спорт', 'Одежда', 'Другое',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (image != null) setState(() => _selectedImage = File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе изображения'), backgroundColor: Colors.grey[700]),
        );
      }
    }
  }

  Future<void> _generateItem() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = AuthService().currentUser;
      if (currentUser == null || !currentUser.canCreateItems) return;

      setState(() => _isLoading = true);

      final newItem = Item(
        itemId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _selectedImage?.path ?? '',
        status: ItemStatus.available,
        price: double.tryParse(_priceController.text),
        category: _categoryController.text.trim().isEmpty ? 'Другое' : _categoryController.text.trim(),
        createdAt: DateTime.now(),
        createdBy: currentUser.id,
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
    setState(() {
      _selectedImage = null;
      _generatedQRData = null;
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF424242),
        title: const Text('Добавить товар', style: TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
      ),
      body: _currentStep == 0 ? _buildFormStep() : _buildQRStep(),
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Шаг 1 из 2', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 24),
              _buildLabel('Изображение'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : Center(
                    child: Text('Нажмите для выбора', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Название *'),
              const SizedBox(height: 8),
              _buildTextField(controller: _nameController, hintText: 'Название товара', validator: (v) => v?.isEmpty == true ? 'Обязательное поле' : null),
              const SizedBox(height: 20),
              _buildLabel('Описание *'),
              const SizedBox(height: 8),
              _buildTextField(controller: _descriptionController, hintText: 'Описание товара', maxLines: 3, validator: (v) => v?.isEmpty == true ? 'Обязательное поле' : null),
              const SizedBox(height: 20),
              _buildLabel('Цена'),
              const SizedBox(height: 8),
              _buildTextField(controller: _priceController, hintText: 'Необязательно', keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildLabel('Категория'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Выберите категорию',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide(color: Colors.grey[700]!)),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                ),
                value: _categoryController.text.isEmpty ? null : _categoryController.text,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _categoryController.text = v ?? ''),
              ),
              const SizedBox(height: 28),
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
                      child: const Text('Отмена', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF616161),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Создать QR-код', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRStep() {
    if (_generatedQRData == null) return const Center(child: Text('Ошибка'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          children: [
            Text('Шаг 2 из 2', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 24),
            const Text('Товар создан', style: TextStyle(fontSize: 16, color: Color(0xFF424242))),
            const SizedBox(height: 24),
            if (_selectedImage != null)
              Container(
                height: 120,
                margin: const EdgeInsets.only(bottom: 16),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: QrImageView(
                data: _generatedQRData!,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Название', _nameController.text),
            _buildInfoRow('Описание', _descriptionController.text),
            if (_priceController.text.isNotEmpty) _buildInfoRow('Цена', '\$${_priceController.text}'),
            if (_categoryController.text.isNotEmpty) _buildInfoRow('Категория', _categoryController.text),
            _buildInfoRow('Дата', DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetForm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF424242),
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    ),
                    child: const Text('Еще один', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF616161),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      elevation: 0,
                    ),
                    child: const Text('Готово', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide(color: Colors.grey[700]!)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
      validator: validator,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF424242)))),
        ],
      ),
    );
  }
}