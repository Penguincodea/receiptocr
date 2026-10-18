import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/receipt_ocr_service.dart';
import 'review_screen.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessingOcr = false;
  FlashMode _flashMode = FlashMode.off;
  Offset? _focusPoint;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _statusMessage = 'Không tìm thấy camera trên thiết bị';
        });
        return;
      }

      // Select back camera if available
      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
        _flashMode = FlashMode.off;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Không thể khởi tạo camera: $e';
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final newMode = _flashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;
      await _cameraController!.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (_) {
      // Flash not supported on device
    }
  }

  Future<void> _onTapPreview(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    setState(() {
      _focusPoint = details.localPosition;
    });

    try {
      await _cameraController!.setFocusPoint(offset);
      await _cameraController!.setExposurePoint(offset);
    } catch (_) {}

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _focusPoint = null;
        });
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessingOcr) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      await _processImageWithOcr(photo.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chụp ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessingOcr) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        await _processImageWithOcr(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processImageWithOcr(String imagePath) async {
    setState(() {
      _isProcessingOcr = true;
    });

    try {
      final parseResult = await ReceiptOcrService.instance.recognizeAndParse(
        imagePath,
      );

      if (!mounted) return;
      setState(() {
        _isProcessingOcr = false;
      });

      // Navigate to review screen
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => ReviewScreen(
            imagePath: imagePath,
            initialMerchant: parseResult.merchantName,
            initialAmount: parseResult.amount,
            initialDate: parseResult.date,
          ),
        ),
      );

      if (saved == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingOcr = false;
      });

      // Show option to enter manually if OCR fails
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nhận diện chưa hoàn tất'),
          content: Text(
            'Không thể đọc chữ trên hóa đơn tự động ($e).\nBạn có muốn tự nhập thông tin không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Chụp lại'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReviewScreen(imagePath: imagePath),
                  ),
                );
              },
              child: const Text('Nhập thủ công'),
            ),
          ],
        ),
      );
    }
  }

  void _openManualEntry() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ReviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét hóa đơn'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_isCameraInitialized)
            IconButton(
              icon: Icon(
                _flashMode == FlashMode.torch
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: _flashMode == FlashMode.torch
                    ? Colors.amber
                    : Colors.white,
              ),
              onPressed: _toggleFlash,
              tooltip: 'Bật/Tắt đèn Flash',
            ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Camera preview or fallback
          if (_isCameraInitialized && _cameraController != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _onTapPreview(details, constraints),
                  child: Center(child: CameraPreview(_cameraController!)),
                );
              },
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 64,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage ?? 'Đang khởi động camera...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Chọn ảnh từ thư viện'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openManualEntry,
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Nhập thông tin thủ công'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Receipt alignment frame & guide
          if (_isCameraInitialized) ...[
            IgnorePointer(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.58,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Căn chỉnh hóa đơn vào khung',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Đảm bảo đủ ánh sáng và chữ rõ nét',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tap-to-focus indicator
            if (_focusPoint != null)
              Positioned(
                left: _focusPoint!.dx - 25,
                top: _focusPoint!.dy - 25,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                ),
              ),
          ],

          // 3. Bottom controls bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
              color: Colors.black.withValues(alpha: 0.75),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Pick from gallery button
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    tooltip: 'Chọn ảnh từ máy',
                    onPressed: _pickFromGallery,
                  ),

                  // Capture Shutter Button
                  InkWell(
                    onTap: _capturePhoto,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFF1E293B),
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Manual entry button
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.edit_note, color: Colors.white),
                    tooltip: 'Nhập thủ công',
                    onPressed: _openManualEntry,
                  ),
                ],
              ),
            ),
          ),

          // 4. Loading overlay during OCR processing
          if (_isProcessingOcr)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Đang nhận diện hóa đơn...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Google ML Kit OCR trên thiết bị',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
