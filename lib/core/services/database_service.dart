import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HistoryItem {
  final int? id;
  final String imagePath;
  final String resultClass;
  final String recommendation;
  final double confidence;
  final DateTime createdAt;

  HistoryItem({
    this.id,
    required this.imagePath,
    required this.resultClass,
    required this.recommendation,
    required this.confidence,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'result_class': resultClass,
      'recommendation': recommendation,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'],
      imagePath: map['image_path'],
      resultClass: map['result_class'],
      recommendation: map['recommendation'],
      confidence: map['confidence'] ?? 0.0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'ffb_history.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT,
        result_class TEXT,
        recommendation TEXT,
        confidence REAL,
        created_at TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS history');
      await _onCreate(db, newVersion);
    }
  }

  Future<int> insertHistory(HistoryItem item) async {
    final db = await database;
    return await db.insert('history', item.toMap());
  }

  Future<List<HistoryItem>> getHistoryList() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('history', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) {
      return HistoryItem.fromMap(maps[i]);
    });
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }
}
