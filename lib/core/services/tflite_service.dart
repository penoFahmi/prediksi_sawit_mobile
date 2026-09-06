import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageQualityException implements Exception {
  final String message;
  ImageQualityException(this.message);
  @override
  String toString() => message;
}

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  Interpreter? _yoloInterpreter;
  Interpreter? _classifierInterpreter;

  final List<String> _labels = ['Lewat Matang', 'Matang', 'Mengkal', 'Mentah'];

  /// Cek apakah platform mendukung TFLite
  bool get _isPlatformSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> loadModel() async {
    if (!_isPlatformSupported) {
      log("Platform tidak mendukung TFLite. Hanya Android & iOS.");
      return;
    }
    try {
      log("Memuat model YOLO dan MobileNet...");
      _yoloInterpreter = await Interpreter.fromAsset('assets/models/yolov8_sawit.tflite');
      _classifierInterpreter = await Interpreter.fromAsset('assets/models/mobilenetv2_sawit_v9_fp16.tflite');
      log("Kedua Model berhasil dimuat!");
    } catch (e) {
      log("Gagal memuat model: $e");
      throw Exception("Gagal memuat model TFLite: $e");
    }
  }

  /// Fungsi Utama Pipeline yang terhubung dengan ResultScreen
  Future<Map<String, dynamic>> classifyImage(String imagePath) async {
    // Guard: Platform tidak didukung
    if (!_isPlatformSupported) {
      return {
        'is_sawit': false,
        'error': 'Fitur deteksi AI hanya tersedia di Android & iOS.\nGunakan perangkat HP untuk menggunakan fitur ini.',
      };
    }

    if (_yoloInterpreter == null || _classifierInterpreter == null) {
      await loadModel(); // Coba muat ulang jika masih null
    }

    try {
      final File imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('Gagal membaca gambar');
      }

      // Tahap 1: Deteksi YOLO
      final yoloResult = _runYoloInference(originalImage);
      if (yoloResult == null || yoloResult['confidence'] < 0.25) {
        return {
          'error': 'Buah Sawit tidak terdeteksi secara jelas di foto ini.',
          'is_sawit': false
        };
      }

      // Tahap 2: Potong Gambar
      int cropX = yoloResult['x'];
      int cropY = yoloResult['y'];
      int cropW = yoloResult['w'];
      int cropH = yoloResult['h'];
      
      cropX = cropX.clamp(0, originalImage.width);
      cropY = cropY.clamp(0, originalImage.height);
      cropW = cropW.clamp(1, originalImage.width - cropX);
      cropH = cropH.clamp(1, originalImage.height - cropY);

      img.Image croppedImage = img.copyCrop(originalImage, x: cropX, y: cropY, width: cropW, height: cropH);

      // Tahap 3: Klasifikasi Kematangan dengan MobileNetV2
      final classificationResult = _runClassification(croppedImage);

      String predictedClass = classificationResult['label'];
      double confidence = classificationResult['confidence'];
      
      return _getRecommendation(predictedClass, confidence);
      
    } catch (e) {
      log("Error processing pipeline: $e");
      throw Exception('Terjadi kesalahan sistem saat memproses gambar');
    }
  }

  Map<String, dynamic> _getRecommendation(String detectedClass, double confidence) {
    String recommendation = '';
    switch (detectedClass) {
      case 'Mentah':
        recommendation = 'Tunggu +14 hari';
        break;
      case 'Mengkal':
        recommendation = 'Tunggu 5-7 hari';
        break;
      case 'Matang':
        recommendation = 'Panen sekarang!';
        break;
      case 'Lewat Matang':
        recommendation = 'Terlambat, segera panen';
        break;
      default:
        recommendation = 'Kelas tidak dikenal';
    }
    return {
      'is_sawit': true,
      'class': detectedClass,
      'recommendation': recommendation,
      'confidence': confidence.toString(),
    };
  }

  /// Menjalankan YOLOv8 dengan Float32List
  Map<String, dynamic>? _runYoloInference(img.Image image) {
    img.Image resizedImage = img.copyResize(image, width: 640, height: 640);
    
    var inputFlat = Float32List(1 * 3 * 640 * 640);
    int rOffset = 0;
    int gOffset = 640 * 640;
    int bOffset = 2 * 640 * 640;
    int pixelIndex = 0;
    
    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = resizedImage.getPixel(x, y);
        inputFlat[rOffset + pixelIndex] = pixel.r / 255.0;
        inputFlat[gOffset + pixelIndex] = pixel.g / 255.0;
        inputFlat[bOffset + pixelIndex] = pixel.b / 255.0;
        pixelIndex++;
      }
    }

    var outputFlat = Float32List(1 * 5 * 8400);
    _yoloInterpreter!.run(inputFlat.buffer, outputFlat.buffer);

    double maxConfidence = 0;
    int bestIndex = -1;

    for (int i = 0; i < 8400; i++) {
      double conf = outputFlat[4 * 8400 + i];
      if (conf > maxConfidence) {
        maxConfidence = conf;
        bestIndex = i;
      }
    }

    if (bestIndex == -1) return null;

    double cx = outputFlat[0 * 8400 + bestIndex];
    double cy = outputFlat[1 * 8400 + bestIndex];
    double w = outputFlat[2 * 8400 + bestIndex];
    double h = outputFlat[3 * 8400 + bestIndex];

    double scaleX = image.width / 640.0;
    double scaleY = image.height / 640.0;

    int finalW = (w * scaleX).round();
    int finalH = (h * scaleY).round();
    int finalX = ((cx - (w / 2)) * scaleX).round();
    int finalY = ((cy - (h / 2)) * scaleY).round();

    return {
      'confidence': maxConfidence,
      'x': finalX,
      'y': finalY,
      'w': finalW,
      'h': finalH
    };
  }

  /// Menjalankan MobileNetV2 dengan Float32List
  Map<String, dynamic> _runClassification(img.Image croppedImage) {
    img.Image resizedImage = img.copyResize(croppedImage, width: 320, height: 320);

    var inputFlat = Float32List(1 * 320 * 320 * 3);
    int pIndex = 0;
    
    for (int y = 0; y < 320; y++) {
      for (int x = 0; x < 320; x++) {
        final pixel = resizedImage.getPixel(x, y);
        // RGB Keras Normalization: [-1, 1]
        inputFlat[pIndex++] = (pixel.r / 127.5) - 1.0;
        inputFlat[pIndex++] = (pixel.g / 127.5) - 1.0;
        inputFlat[pIndex++] = (pixel.b / 127.5) - 1.0;
      }
    }

    var outputFlat = Float32List(4);
    _classifierInterpreter!.run(inputFlat.buffer, outputFlat.buffer);

    double maxProb = 0;
    int maxIndex = -1;
    for (int i = 0; i < 4; i++) {
      if (outputFlat[i] > maxProb) {
        maxProb = outputFlat[i];
        maxIndex = i;
      }
    }

    return {
      'label': _labels[maxIndex],
      'confidence': maxProb
    };
  }
} 