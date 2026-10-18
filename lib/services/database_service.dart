import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense_item.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'expenses_v1.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant_name TEXT NOT NULL,
            amount INTEGER NOT NULL,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            note TEXT,
            receipt_image_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Insert a new expense
  Future<int> insertExpense(ExpenseItem item) async {
    final db = await database;
    return await db.insert('expenses', item.toMap());
  }

  /// Fetch all expenses ordered by date descending, then id descending
  Future<List<ExpenseItem>> getAllExpenses() async {
    final db = await database;
    final results = await db.query('expenses', orderBy: 'date DESC, id DESC');
    return results.map((map) => ExpenseItem.fromMap(map)).toList();
  }

  /// Delete an expense by ID
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Update an expense
  Future<int> updateExpense(ExpenseItem item) async {
    if (item.id == null) return 0;
    final db = await database;
    return await db.update(
      'expenses',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Permanently copies a receipt image to the app's document directory
  Future<String> saveReceiptImage(String sourceFilePath) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        return sourceFilePath;
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDocDir.path, 'receipt_images'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName =
          'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourceFilePath)}';
      final targetPath = p.join(receiptsDir.path, fileName);

      final savedFile = await sourceFile.copy(targetPath);
      return savedFile.path;
    } catch (e) {
      // Fallback to original path if copy fails
      return sourceFilePath;
    }
  }
}
