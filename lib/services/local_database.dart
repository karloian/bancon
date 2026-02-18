import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bancon_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const intType = 'INTEGER';
    const realType = 'REAL';

    await db.execute('''
      CREATE TABLE offline_stores (
        local_id $idType,
        store_name $textType,
        date $textType,
        purchaser_owner $textType,
        contact_number $textType,
        complete_address $textType,
        territory $textType,
        store_classification $textType,
        tin $textType,
        payment_term $textType,
        price_level $textType,
        agent_code $textType,
        sales_person $textType,
        store_picture_url $textType,
        business_permit_url $textType,
        map_latitude $realType,
        map_longitude $realType,
        agent_id $textType,
        sync_status $textType,
        created_at $textType,
        error_message $textType
      )
    ''');
  }

  Future<String> insertStore(Map<String, dynamic> store) async {
    final db = await database;
    final localId = DateTime.now().millisecondsSinceEpoch.toString();

    final storeData = {
      'local_id': localId,
      ...store,
      'sync_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    };

    await db.insert('offline_stores', storeData);
    return localId;
  }

  Future<List<Map<String, dynamic>>> getPendingStores() async {
    final db = await database;
    return await db.query(
      'offline_stores',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllStores() async {
    final db = await database;
    return await db.query('offline_stores', orderBy: 'created_at DESC');
  }

  Future<int> updateSyncStatus(
    String localId,
    String status, {
    String? errorMessage,
  }) async {
    final db = await database;
    return await db.update(
      'offline_stores',
      {
        'sync_status': status,
        if (errorMessage != null) 'error_message': errorMessage,
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<int> deleteStore(String localId) async {
    final db = await database;
    return await db.delete(
      'offline_stores',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_stores WHERE sync_status = ?',
      ['pending'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearSyncedStores() async {
    final db = await database;
    await db.delete(
      'offline_stores',
      where: 'sync_status = ?',
      whereArgs: ['synced'],
    );
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
