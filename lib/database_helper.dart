import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "inventario.db");

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE itens(id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT, imagem_path TEXT)",
        );
      },
    );
  }

  // CREATE (Adicionar item) 
  static Future<int> insertItem(String nome, String imagemPath) async {
    final db = await getDatabase();
    return await db.insert(
      'itens',
      {'nome': nome, 'imagem_path': imagemPath},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ (Listar itens)
  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await getDatabase();
    return await db.query('itens', orderBy: 'id DESC');
  }

// UPDATE (Editar item)
  static Future<int> updateItem(int id, String novoNome, String? imagemPath) async {
    final db = await getDatabase(); 

    final dados = {
      'nome': novoNome,
      'imagem_path': imagemPath, 
    };

   
    final resultado = await db.update(
      'itens', 
      dados, 
      where: "id = ?", 
      whereArgs: [id]
    );
    
    return resultado;
  }


  static Future<void> deleteItem(int id) async {
    final db = await getDatabase();
    await db.delete(
      'itens',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}