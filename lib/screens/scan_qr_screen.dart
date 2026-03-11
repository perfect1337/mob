import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/item.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({Key? key}) : super(key: key);

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  bool _isProcessing = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  MobileScannerController? _mobileController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _mobileController = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _mobileController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? qrData = barcode.rawValue;
      
      if (qrData != null && qrData.isNotEmpty) {
        _processQRData(qrData);
        break;
      }
    }
  }

  void _processQRData(String qrData) {
    final item = Item.fromQRData(qrData);

    if (item != null) {
      _showSuccessDialog(item);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Не удалось распознать QR-код';
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 60,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                'Сканирование через веб',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Для сканирования QR-кодов используйте мобильное приложение.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.grey.shade800,
                ),
                child: const Text('Вернуться назад'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _mobileController!,
          onDetect: _onDetect,
        ),

        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned(top: -1, left: -1, child: _buildCorner()),
                Positioned(top: -1, right: -1, child: _buildCorner()),
                Positioned(bottom: -1, left: -1, child: _buildCorner()),
                Positioned(bottom: -1, right: -1, child: _buildCorner()),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Поместите QR-код в область сканирования',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),

        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
              ),
            ),
          ),

        if (_hasError)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
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
          ),
      ],
    );
  }

  Widget _buildCorner() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade400, width: 2),
          left: BorderSide(color: Colors.grey.shade400, width: 2),
        ),
      ),
    );
  }
}