import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'tarefa.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = join(await getDatabasesPath(), 'tarefa.db');

    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tarefas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            descricao TEXT NOT NULL,
            prioridade TEXT NOT NULL,
            status TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertTarefa(Tarefa tarefa) async {
    final db = await database;
    return await db.insert('tarefas', tarefa.toMap());
  }

  Future<List<Tarefa>> getTarefas() async {
    final db = await database;
    final resultado = await db.query('tarefas', orderBy: 'id DESC');
    return resultado.map((map) => Tarefa.fromMap(map)).toList();
  }

  Future<int> updateTarefa(Tarefa tarefa) async {
    final db = await database;
    return await db.update(
      'tarefas',
      tarefa.toMap(),
      where: 'id = ?',
      whereArgs: [tarefa.id],
    );
  }

  Future<int> deleteTarefa(int id) async {
    final db = await database;
    return await db.delete('tarefas', where: 'id = ?', whereArgs: [id]);
  }
}