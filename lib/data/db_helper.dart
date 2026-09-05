import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import '../models/saved_outfit.dart';
import 'schema.dart';

/// onCreate 回调：建表（应用与测试共用）
Future<void> migrate(Database db, int version) async {
  for (final stmt in schemaStatements) {
    await db.execute(stmt);
  }
}

/// SQLite 封装（应用侧单例）
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'ai_da_yi.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: migrate,
      onUpgrade: (db, oldVersion, newVersion) async {
        // v2：outfit 表增加 snapshot 快照列（收藏 / OOTD 记录）
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE outfit ADD COLUMN snapshot TEXT');
        }
      },
    );
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ---- 个人档案 ----
  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    final map = profile.toMap()..remove('id');
    return db.insert('user_profile', map);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final db = await database;
    final id = profile.id;
    if (id == null) return;
    await db.update('user_profile', profile.toMap(),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final rows = await db.query('user_profile', orderBy: 'id');
    if (rows.isEmpty) return null;
    // 自愈：历史版本曾重复插入档案，只保留最早一行
    for (final r in rows.skip(1)) {
      await db.delete('user_profile', where: 'id = ?', whereArgs: [r['id']]);
    }
    return UserProfile.fromMap(rows.first);
  }

  // ---- 衣橱单品 ----
  Future<int> insertWardrobeItem(WardrobeItem item) async {
    final db = await database;
    final map = item.toMap()..remove('id');
    return db.insert('wardrobe_item', map);
  }

  Future<List<WardrobeItem>> getWardrobeItems() async {
    final db = await database;
    final rows = await db.query('wardrobe_item');
    return rows.map(WardrobeItem.fromMap).toList();
  }

  Future<void> deleteWardrobeItem(int id) async {
    final db = await database;
    await db.delete('wardrobe_item', where: 'id = ?', whereArgs: [id]);
  }

  // ---- 收藏 / OOTD 记录 ----

  /// 保存一套穿搭：快照存全部单品（含未入库的模板单品），关联表存已入库单品的 id
  Future<int> saveOutfit({
    String? occasion,
    String? targetStyle,
    double? totalScore,
    String? colorNote,
    required List<(String, WardrobeItem)> slots,
  }) async {
    final db = await database;
    final snapshot = jsonEncode([
      for (final (slot, item) in slots)
        {'slot': slot, 'item': item.toMap()},
    ]);

    final outfitId = await db.insert('outfit', {
      'occasion': occasion,
      'target_style': targetStyle,
      'total_score': totalScore,
      'color_note': colorNote,
      'snapshot': snapshot,
    });

    final batch = db.batch();
    for (final (slot, item) in slots) {
      final id = item.id;
      if (id != null) {
        batch.insert('outfit_item',
            {'outfit_id': outfitId, 'item_id': id, 'slot': slot});
      }
    }
    await batch.commit(noResult: true);
    return outfitId;
  }

  Future<List<SavedOutfit>> getSavedOutfits() async {
    final db = await database;
    final rows = await db.query('outfit', orderBy: 'id DESC');
    return rows.map(SavedOutfit.fromMap).toList();
  }

  Future<void> deleteOutfit(int id) async {
    final db = await database;
    await db.delete('outfit_item', where: 'outfit_id = ?', whereArgs: [id]);
    await db.delete('outfit', where: 'id = ?', whereArgs: [id]);
  }

  // ---- 品类 ----
  Future<void> insertCategory(Category c) async {
    final db = await database;
    await db.insert('category', c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('category', orderBy: 'id');
    return rows.map(Category.fromMap).toList();
  }

  // ---- 风格 ----
  Future<void> insertStyle(Style s) async {
    final db = await database;
    await db.insert('style', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Style>> getStyles() async {
    final db = await database;
    final rows = await db.query('style');
    return rows.map(Style.fromMap).toList();
  }

  // ---- 体型规则 ----
  Future<void> insertBodyTypeRule(BodyTypeRule r) async {
    final db = await database;
    await db.insert('body_type_rule', r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BodyTypeRule>> getBodyTypeRules() async {
    final db = await database;
    final rows = await db.query('body_type_rule');
    return rows.map(BodyTypeRule.fromMap).toList();
  }
}
