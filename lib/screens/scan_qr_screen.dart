import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:js' as js;
import '../models/item.dart';
import 'dart:convert';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({Key? key}) : super(key: key);

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  bool _isProcessing = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _qrFound = false;

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _hasError = false;
      _qrFound = false;
    });

    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((event) async {
      if (input.files == null || input.files!.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final file = input.files![0];

      setState(() {
        _errorMessage = 'Загрузка изображения...';
      });

      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) async {
        final bytes = reader.result as Uint8List;
        await _compressAndDecode(bytes);
      });

      reader.readAsArrayBuffer(file);
    });
  }

  Future<void> _compressAndDecode(Uint8List bytes) async {
    try {
      setState(() {
        _errorMessage = 'Сжатие изображения...';
      });

      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final img = html.ImageElement();
      img.src = url;

      await img.onLoad.first;

      final originalWidth = img.width!;
      final originalHeight = img.height!;

      int newWidth = originalWidth;
      int newHeight = originalHeight;

      if (originalWidth > 800 || originalHeight > 800) {
        if (originalWidth > originalHeight) {
          newWidth = 800;
          newHeight = (originalHeight * 800 / originalWidth).round();
        } else {
          newHeight = 800;
          newWidth = (originalWidth * 800 / originalHeight).round();
        }
      }

      setState(() {
        _errorMessage = 'Распознавание QR-кода...';
      });

      final canvas = html.CanvasElement(width: newWidth, height: newHeight);
      final ctx = canvas.context2D;
      ctx.drawImageScaled(img, 0, 0, newWidth, newHeight);

      final imageData = ctx.getImageData(0, 0, newWidth, newHeight);

      html.Url.revokeObjectUrl(url);

      await Future.delayed(const Duration(milliseconds: 50));

      final jsQR = js.context['jsQR'];

      if (jsQR == null) {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _errorMessage = 'Ошибка: библиотека не загружена';
        });
        return;
      }

      final result = jsQR.callMethod('call', [
        js.context,
        imageData.data,
        newWidth,
        newHeight
      ]);

      if (result != null && result['data'] != null && result['data'].toString().isNotEmpty) {
        _processQRData(result['data'].toString());
      } else {
        setState(() {
          _isProcessing = false;
          _hasError = true;
          _errorMessage = 'QR-код не найден. Убедитесь, что изображение содержит четкий QR-код.';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _hasError = false;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _errorMessage = 'Ошибка: $e';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _hasError = false;
          });
        }
      });
    }
  }

  void _processQRData(String qrData) {
    try {
      Map<String, dynamic> json = jsonDecode(qrData);

      final item = Item(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String? ?? '',
        status: ItemStatus.available,
        price: json['price'] != null ? (json['price'] as num).toDouble() : null,
        category: json['category'] as String?,
        createdAt: DateTime.now(),
        qrData: qrData,
      );

      setState(() {
        _isProcessing = false;
      });

      _showSuccessDialog(item);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _errorMessage = 'Неверный формат QR-кода. Данные: ${qrData.substring(0, qrData.length > 50 ? 50 : qrData.length)}';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _hasError = false;
          });
        }
      });
    }
  }

  void _showSuccessDialog(Item item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('QR-код распознан'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.grey.shade700,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Название: ${item.name}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Описание: ${item.description}', style: const TextStyle(fontSize: 13)),
                  if (item.price != null) ...[
                    const SizedBox(height: 4),
                    Text('Цена: \$${item.price!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Продолжить', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
            ),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканировать QR-код'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 60,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Выберите изображение с QR-кодом',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Нажмите на кнопку и выберите фото из галереи',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('ВЫБРАТЬ ФОТО'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _errorMessage.isNotEmpty ? _errorMessage : 'Обработка...',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
              if (_hasError && !_isProcessing) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey.shade300, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}