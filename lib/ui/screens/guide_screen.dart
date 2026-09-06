import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Penggunaan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cara Menggunakan Aplikasi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ikuti langkah-langkah berikut untuk mendapatkan hasil prediksi kematangan sawit yang akurat.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildStep(
              '1',
              'Pilih Metode Input',
              'Di halaman utama, pilih "Ambil dari Kamera" jika Anda berada langsung di perkebunan, atau "Pilih dari Galeri" jika Anda sudah memiliki foto sawit sebelumnya.',
            ),
            _buildStep(
              '2',
              'Perhatikan Pencahayaan',
              'Pastikan objek Tandan Buah Segar (TBS) terlihat jelas, tidak terlalu gelap, dan tidak blur. Aplikasi akan menolak foto yang terlalu gelap untuk menjaga akurasi AI.',
            ),
            _buildStep(
              '3',
              'Tunggu Proses Analisis AI',
              'Setelah foto diambil, sistem kecerdasan buatan (MobileNetV2) akan menganalisis warna dan tekstur sawit secara otomatis tanpa membutuhkan koneksi internet.',
            ),
            _buildStep(
              '4',
              'Baca Hasil & Rekomendasi',
              'Layar akan menampilkan kategori kematangan beserta "Confidence Score" (persentase keyakinan sistem). Ikuti teks rekomendasi waktu panen yang diberikan di layar.',
            ),
            _buildStep(
              '5',
              'Cek Riwayat Panen',
              'Semua hasil deteksi akan tersimpan otomatis di database lokal perangkat Anda. Anda dapat melihat kembali daftarnya kapan saja melalui tombol "Riwayat" (ikon jam) di pojok kanan atas.',
            ),
          ],
        ),
      ),
    );
  }
}
