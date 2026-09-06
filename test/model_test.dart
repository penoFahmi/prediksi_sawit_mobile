import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Check Model Shapes', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    
    print('--- YOLOv8 ---');
    try {
      final yolo = await Interpreter.fromAsset('assets/models/yolov8_sawit.tflite');
      final input = yolo.getInputTensor(0);
      final output = yolo.getOutputTensor(0);
      print('YOLO Input Shape: \${input.shape}');
      print('YOLO Input Type: \${input.type}');
      print('YOLO Output Shape: \${output.shape}');
      print('YOLO Output Type: \${output.type}');
    } catch (e) {
      print('Error loading YOLO: $e');
    }

    print('--- MobileNetV2 ---');
    try {
      final mobilenet = await Interpreter.fromAsset('assets/models/mobilenetv2_sawit_v9_fp16.tflite');
      final input = mobilenet.getInputTensor(0);
      final output = mobilenet.getOutputTensor(0);
      print('MobileNet Input Shape: \${input.shape}');
      print('MobileNet Input Type: \${input.type}');
      print('MobileNet Output Shape: \${output.shape}');
      print('MobileNet Output Type: \${output.type}');
    } catch (e) {
      print('Error loading MobileNet: $e');
    }
  });
}
