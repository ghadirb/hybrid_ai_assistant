
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
class LocalMemoryDB {
  static Database? _db;
  static Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'memory.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT, audio_path TEXT, is_user INTEGER, ts INTEGER)''');
    });
    return _db!;
  }
  static Future<int> addMessage(String text, String audioPath, bool isUser) async {
    final db = await database;
    return db.insert('messages', {'text': text, 'audio_path': audioPath, 'is_user': isUser?1:0, 'ts': DateTime.now().millisecondsSinceEpoch});
  }
  static Future<List<Map<String,dynamic>>> getMessages() async {
    final db = await database;
    return db.query('messages', orderBy: 'ts ASC');
  }
}
