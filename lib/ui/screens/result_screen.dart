import 'dart:io';
import 'package:flutter/material.dart';
import 'package:prediksi_sawit_mobile/core/services/database_service.dart';
import 'package:prediksi_sawit_mobile/core/services/tflite_service.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _predictedClass;
  String? _recommendation;
  double? _confidence;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final result = await TFLiteService().classifyImage(widget.imagePath);
      
      if (result['is_sawit'] == false) {
        throw ImageQualityException(result['error'] ?? 'Objek bukan buah sawit.');
      }

      setState(() {
        _predictedClass = result['class'];
        _recommendation = result['recommendation'];
        // TFLiteService sekarang mengembalikan string untuk confidence
        _confidence = double.tryParse(result['confidence'].toString());
        _isLoading = false;
      });

      // Save to local history
      await DatabaseService().insertHistory(
        HistoryItem(
          imagePath: widget.imagePath,
          resultClass: _predictedClass!,
          recommendation: _recommendation!,
          confidence: _confidence ?? 0.0,
          createdAt: DateTime.now(),
        ),
      );

    } on ImageQualityException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memproses gambar: $e';
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Peringatan Deteksi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen (Home/Camera)
            },
            child: const Text('Ambil Ulang'),
          ),
        ],
      ),
    );
  }

  Color _getClassColor(String? className) {
    switch (className) {
      case 'Mentah':
        return Colors.blueGrey;
      case 'Mengkal':
        return Colors.orange;
      case 'Matang':
        return Colors.green;
      case 'Lewat Matang':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Deteksi'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memproses gambar...')
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(widget.imagePath),
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_errorMessage != null) ...[
                      // Tampilan jika ditolak oleh YOLO
                      Card(
                        color: Colors.red.shade50,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.red, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Tampilan jika berhasil (Sawit terdeteksi)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Text(
                                'Hasil Klasifikasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _predictedClass ?? '-',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: _getClassColor(_predictedClass),
                                ),
                              ),
                              if (_confidence != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Akurasi: ${(_confidence! * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              const Divider(height: 32, thickness: 1),
                              const Text(
                                'Rekomendasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _recommendation ?? '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Kembali ke Beranda', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
