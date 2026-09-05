import 'dart:io';
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

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // TensorFlow/Keras default class order is alphabetical based on folder names:
  // 1. Lewat Matang
  // 2. Matang
  // 3. Mengkal
  // 4. Mentah
  final List<String> _labels = ['Lewat Matang', 'Matang', 'Mengkal', 'Mentah'];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      _isModelLoaded = true;
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      _isModelLoaded = false;
    }
  }

  Future<Map<String, String>> classifyImage(String imagePath) async {
    // 1. Load image
    final File imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final img.Image? decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }

    // 2. Quality check (mock implementation for blur/darkness)
    // A simple brightness check using luminance
    double totalBrightness = 0;
    for (final pixel in decodedImage) {
      totalBrightness += (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
    }
    double avgBrightness = totalBrightness / (decodedImage.width * decodedImage.height);
    
    if (avgBrightness < 30) {
      throw ImageQualityException('Foto terlalu gelap, silakan ambil ulang gambar');
    }

    // 3. Inference (if model loaded, else mock)
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception('Model AI gagal dimuat. Pastikan file model.tflite ada dan aplikasi telah di-restart sepenuhnya.');
    }

    // 4. Preprocess for MobileNetV2 (224x224, float32, normalized to [-1, 1] or [0, 1] depending on model)
    // Assuming standard ImageNet normalization or [0, 1]
    final img.Image resizedImage = img.copyResize(decodedImage, width: 224, height: 224);
    
    // Create input tensor [1, 224, 224, 3]
    var input = List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            // Normalisasi [0.0 - 1.0] yang sering dipakai jika dilatih dengan rescale=1./255
            return [
              pixel.r / 255.0, // R
              pixel.g / 255.0, // G
              pixel.b / 255.0, // B
            ];
          },
        ),
      ),
    );

    // Create output tensor [1, 4] (4 classes)
    var output = List.generate(1, (i) => List.filled(4, 0.0));

    // Run inference
    _interpreter!.run(input, output);

    // Get max probability class
    final probabilities = output[0];
    int maxIndex = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    String predictedClass = _labels[maxIndex];
    return _getRecommendation(predictedClass, maxProb);
  }

  Map<String, String> _getRecommendation(String detectedClass, double confidence) {
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
      'class': detectedClass,
      'recommendation': recommendation,
      'confidence': confidence.toString(),
    };
  }
  
  void dispose() {
    _interpreter?.close();
  }
}
