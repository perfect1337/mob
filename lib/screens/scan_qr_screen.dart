import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> with WidgetsBindingObserver {
  MobileScannerController? cameraController;
  bool isProcessing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (cameraController == null) {
      _initController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed && _isInitialized && cameraController != null) {
      _startScanner();
    } else if (state == AppLifecycleState.paused && cameraController != null) {
      _stopScanner();
    }
  }

  Future<void> _initController() async {
    await _disposeController();

    cameraController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    setState(() {});
    await _startScanner();
  }

  Future<void> _startScanner() async {
    if (cameraController == null || !mounted) return;

    try {
      if (!cameraController!.value.isInitialized) {
        await cameraController!.start();
        _isInitialized = true;
      }
    } on PlatformException catch (e) {
      if (e.code == 'PermissionDenied' && mounted) {
        _showPermissionDialog();
      }
    } catch (e) {

    }
  }

  Future<void> _stopScanner() async {
    if (cameraController == null || !mounted) return;

    try {
      if (cameraController!.value.isInitialized) {
        await cameraController!.stop();
      }
    } catch (e) {

    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Доступ к камере'),
        content: const Text(
          'Для сканирования QR-кодов приложению необходим доступ к камере.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualInstructions();
            },
            child: const Text('Как разрешить?'),
          ),
        ],
      ),
    );
  }

  void _showManualInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Инструкция'),
        content: const Text(
          '1. Откройте настройки телефона\n'
              '2. Перейдите в раздел "Приложения"\n'
              '3. Найдите приложение\n'
              '4. Нажмите "Разрешения"\n'
              '5. Включите доступ к камере',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final BarcodeCapture? barcodeCapture = await MobileScannerPlatform.instance.analyzeImage(image.path);

      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final String? scannedValue = barcodeCapture.barcodes.first.rawValue;
        if (scannedValue != null && scannedValue.isNotEmpty) {
          if (mounted) {
            await _stopScanner();
            _processScannedData(scannedValue);
            return;
          }
        } else {
          _showError('QR-код не содержит данных');
        }
      } else {
        _showError('Не удалось найти QR-код на изображении');
      }
    } catch (e) {
      _showError('Ошибка при анализе изображения');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _processScannedData(String rawData) {
    try {
      final Map<String, dynamic> jsonData = jsonDecode(rawData);

      // ИСПРАВЛЕНО: используем itemId вместо id
      final scannedItem = Item(
        itemId: jsonData['itemId'] as String? ?? jsonData['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: jsonData['name'] as String? ?? 'Без названия',
        description: jsonData['description'] as String? ?? 'Нет описания',
        imageUrl: jsonData['imageUrl'] as String? ?? '',
        status: ItemStatus.available,
        price: jsonData['price'] != null ? (jsonData['price'] as num).toDouble() : null,
        category: jsonData['category'] as String?,
        createdAt: jsonData['createdAt'] != null
            ? DateTime.parse(jsonData['createdAt'] as String)
            : DateTime.now(),
        qrData: rawData,
      );

      Navigator.pop(context, scannedItem);
    } catch (e) {
      Navigator.pop(context, rawData);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканировать QR-код'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController?.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController?.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: cameraController == null
                ? const Center(child: CircularProgressIndicator())
                : MobileScanner(
              controller: cameraController!,
              onDetect: (capture) async {
                if (!isProcessing && mounted && cameraController != null) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                      setState(() {
                        isProcessing = true;
                      });
                      await _stopScanner();
                      if (mounted) {
                        _processScannedData(barcode.rawValue!);
                      }
                      break;
                    }
                  }
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: isProcessing ? null : _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Выбрать из галереи'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    if (cameraController != null) {
      try {
        await cameraController!.stop();
        await cameraController!.dispose();
      } catch (e) {

      }
      cameraController = null;
    }
    _isInitialized = false;
  }
}