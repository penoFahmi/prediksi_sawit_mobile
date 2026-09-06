import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  Widget _buildInfoCard(String title, String description, Color color, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edukasi Kematangan Sawit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Standar Kematangan Tandan Buah Segar (TBS)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Untuk menghasilkan CPO (Crude Palm Oil) dengan kualitas maksimal dan asam lemak bebas (ALB) yang rendah, penentuan waktu panen sangat krusial. Berikut adalah klasifikasi kematangan TBS:',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            
            _buildInfoCard(
              'Mentah',
              'Warna buah masih hitam gelap atau ungu pekat. Belum ada berondolan yang lepas dari tandan. Buah ini memiliki kandungan minyak yang sangat rendah dan tidak boleh dipanen karena dapat merugikan pabrik (rendemen turun).',
              Colors.blueGrey,
              Icons.do_not_disturb_alt,
            ),
            
            _buildInfoCard(
              'Mengkal',
              'Warna buah mulai berubah menjadi kemerahan. Mulai ada 1-2 berondolan yang lepas dari tandan (tergantung berat tandan). Buah sudah mulai menghasilkan minyak, namun belum mencapai titik maksimal.',
              Colors.orange,
              Icons.warning_amber_rounded,
            ),
            
            _buildInfoCard(
              'Matang',
              'Warna buah sudah orange kemerahan secara merata. Terdapat banyak berondolan yang membrondol secara alami di piringan pohon. Inilah fase paling ideal untuk dipanen dengan rendemen minyak paling tinggi.',
              Colors.green,
              Icons.check_circle_outline,
            ),
            
            _buildInfoCard(
              'Lewat Matang',
              'Warna buah merah tua cenderung kusam atau mulai membusuk. Sangat banyak berondolan yang lepas bahkan buah kosong. Buah ini menghasilkan Asam Lemak Bebas (ALB) yang tinggi sehingga kualitas minyak CPO menjadi sangat buruk.',
              Colors.red,
              Icons.error_outline,
            ),
          ],
        ),
      ),
    );
  }
}
