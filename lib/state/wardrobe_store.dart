import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;

import '../core/color_harmony.dart';
import '../data/db_helper.dart';
import '../data/seed_loader.dart';
import '../data/style_template_loader.dart';
import '../engine/matching_engine.dart';
import '../engine/scoring.dart';
import '../models/models.dart';
import '../models/style_template.dart';
import '../services/app_settings.dart';
import '../services/kb_sync.dart';
import '../services/usage_stats.dart';

/// 全局衣橱状态（单例，UI 通过 ListenableBuilder 订阅）
class WardrobeStore extends ChangeNotifier {
  WardrobeStore._();
  static final WardrobeStore instance = WardrobeStore._();

  final List<WardrobeItem> items = [];
  UserProfile profile = const UserProfile(gender: 'female', bodyType: '梨形');
  final List<Style> styles = [];
  final List<BodyTypeRule> bodyTypeRules = [];
  final List<StyleTemplate> templates = [];
  final List<Category> categories = [];
  ScoringConfig config = const ScoringConfig();
  Set<String> usedFingerprints = {};

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final db = await DatabaseHelper.instance.database;

      // 知识库同步：内容变化（首次运行 / kb_override 覆盖）时自动重导
      final reimported = await KbSync.syncIfNeeded(db);
      if (reimported) debugPrint('[爱搭衣] 知识库已更新并重新导入');

      var dbStyles = await DatabaseHelper.instance.getStyles();
      if (dbStyles.isEmpty) {
        await SeedLoader(db).seedFromAssets();
        dbStyles = await DatabaseHelper.instance.getStyles();
      }
      styles.addAll(dbStyles);

      final rules = await DatabaseHelper.instance.getBodyTypeRules();
      if (rules.isNotEmpty) bodyTypeRules.addAll(rules);

      final p = await DatabaseHelper.instance.getUserProfile();
      if (p != null) profile = p;

      final dbItems = await DatabaseHelper.instance.getWardrobeItems();
      if (dbItems.isNotEmpty) items.addAll(dbItems);

      categories.addAll(await DatabaseHelper.instance.getCategories());
    } catch (e) {
      debugPrint('[爱搭衣] 初始化加载失败，使用演示数据: $e');
    }

  if (items.isEmpty) _seedDemo();
  if (styles.isEmpty) styles.addAll(_defaultStyles());
  if (bodyTypeRules.isEmpty) bodyTypeRules.addAll(_defaultRules());

  // 风格模板（示例搭配），加载失败则保持为空
  try {
    templates.addAll(await loadStyleTemplates());
  } catch (_) {}

  // 设置（评分权重）与使用统计
  try {
    config = await AppSettings.loadConfig();
    usedFingerprints = await UsageStats.usedFingerprints();
  } catch (e) {
    debugPrint('[爱搭衣] 设置/使用统计加载失败: $e');
  }

  notifyListeners();
  }

  void addItem(WardrobeItem item) {
    var it = item;
    // 补写 HSV（此前该列从未写入）
    if ((it.hsvMain == null || it.hsvMain!.isEmpty) &&
        it.colorMain != null &&
        it.colorMain!.isNotEmpty) {
      final hsv = hexToHsv(it.colorMain!);
      it = it.copyWith(
          hsvMain:
              '${hsv.h.toStringAsFixed(1)},${hsv.s.toStringAsFixed(3)},${hsv.v.toStringAsFixed(3)}');
    }
    items.add(it);
    notifyListeners();
    _persistItem(it);
  }

  void removeItem(WardrobeItem item) {
    items.remove(item);
    notifyListeners();
    _deleteItem(item);
  }

  Future<void> _deleteItem(WardrobeItem item) async {
    final id = item.id;
    if (id == null) return; // 演示数据未入库，无需删除
    try {
      await DatabaseHelper.instance.deleteWardrobeItem(id);
    } catch (e) {
      debugPrint('[爱搭衣] 删除单品失败 id=$id: $e');
    }
    // 顺手清理拍照取色保存的图片文件
    final img = item.imagePath;
    if (img != null && img.isNotEmpty) {
      try {
        final f = File(img);
        if (await f.exists()) await f.delete();
      } catch (e) {
        debugPrint('[爱搭衣] 删除单品图片失败: $e');
      }
    }
  }

  void updateProfile(UserProfile p) {
    profile = p;
    notifyListeners();
    _persistProfile(p);
  }

  void updateConfig(ScoringConfig c) {
    config = c;
    notifyListeners();
    AppSettings.saveConfig(c);
  }

  /// 记录单品出现在搭配结果中（反推利用率）
  void recordUsed(Iterable<WardrobeItem> items) {
    UsageStats.record(items);
    for (final i in items) {
      usedFingerprints.add(itemFingerprint(i));
    }
    notifyListeners();
  }

  /// 手动重导知识库（支持 kb_override 覆盖文件），返回是否有变化
  Future<bool> resyncKnowledge() async {
    var changed = false;
    try {
      final db = await DatabaseHelper.instance.database;
      changed = await KbSync.syncIfNeeded(db, force: true);
      styles..clear()..addAll(await DatabaseHelper.instance.getStyles());
      categories
        ..clear()
        ..addAll(await DatabaseHelper.instance.getCategories());
      bodyTypeRules
        ..clear()
        ..addAll(await DatabaseHelper.instance.getBodyTypeRules());
      templates..clear()..addAll(await loadStyleTemplates());
    } catch (e) {
      debugPrint('[爱搭衣] 知识库重导失败: $e');
      return false;
    }
    notifyListeners();
    return changed;
  }

  Future<void> _persistItem(WardrobeItem item) async {
    try {
      final id = await DatabaseHelper.instance.insertWardrobeItem(item);
      final idx = items.indexWhere((e) => identical(e, item));
      if (idx >= 0 && id > 0) {
        items[idx] = item.copyWith(id: id);
        notifyListeners();
      } else if (id > 0) {
        // 落库期间已被删除：清掉刚插入的行，避免重启后"复活"
        await DatabaseHelper.instance.deleteWardrobeItem(id);
      }
    } catch (e) {
      debugPrint('[爱搭衣] 单品落库失败: $e');
    }
  }

  Future<void> _persistProfile(UserProfile p) async {
    try {
      if (p.id == null) {
        final id = await DatabaseHelper.instance.insertUserProfile(p);
        profile = p.copyWith(id: id);
        notifyListeners();
      } else {
        await DatabaseHelper.instance.updateUserProfile(p);
      }
    } catch (e) {
      debugPrint('[爱搭衣] 档案保存失败: $e');
    }
  }

  void _seedDemo() {
    items.addAll(const [
      WardrobeItem(
          slot: 'top', gender: 'female', categoryName: '针织衫',
          colorMain: '#F0E6D3', fit: '标准', season: ['春', '秋'],
          styleTags: ['法式', '通勤'], formalLevel: 3, exposure: 1),
      WardrobeItem(
          slot: 'top', gender: 'female', categoryName: '衬衫',
          colorMain: '#FFFFFF', fit: '修身', season: ['春', '夏'],
          styleTags: ['通勤'], formalLevel: 4, exposure: 1),
      WardrobeItem(
          slot: 'bottom', gender: 'female', categoryName: '西裤',
          colorMain: '#1F3A5F', fit: '直筒', season: ['春', '秋'],
          styleTags: ['通勤'], formalLevel: 4, exposure: 1),
      WardrobeItem(
          slot: 'bottom', gender: 'female', categoryName: '半身裙',
          colorMain: '#7C3A2D', fit: 'A字', season: ['春', '秋'],
          styleTags: ['法式', '复古'], formalLevel: 3, exposure: 2),
      WardrobeItem(
          slot: 'dress', gender: 'female', categoryName: '连衣裙',
          colorMain: '#B8604A', fit: '收腰', season: ['夏'],
          styleTags: ['法式'], formalLevel: 3, exposure: 2),
      WardrobeItem(
          slot: 'shoes', gender: 'female', categoryName: '乐福鞋',
          colorMain: '#1E1D1B', season: ['春', '秋', '冬'],
          styleTags: ['通勤', '法式'], formalLevel: 4, exposure: 0),
      WardrobeItem(
          slot: 'shoes', gender: 'female', categoryName: '帆布鞋',
          colorMain: '#FFFFFF', season: ['春', '夏'],
          styleTags: ['休闲'], formalLevel: 1, exposure: 0),
    ]);
  }

  List<Style> _defaultStyles() => const [
        Style(name: '通勤', gender: 'female', formalLevel: 4, features: ['得体', '中性色']),
        Style(name: '法式', gender: 'female', formalLevel: 3, features: ['优雅', '米白', '驼']),
        Style(name: '极简', gender: 'female', formalLevel: 3, features: ['纯色', '基础款']),
        Style(name: '复古', gender: 'female', formalLevel: 3, features: ['格纹', '酒红']),
        Style(name: '街头', gender: 'female', formalLevel: 1, features: ['oversize', '撞色']),
      ];

  List<BodyTypeRule> _defaultRules() => const [
        BodyTypeRule(gender: 'female', bodyType: '梨形', slot: 'bottom', attribute: '颜色=深色', effect: 1),
        BodyTypeRule(gender: 'female', bodyType: '梨形', slot: 'bottom', attribute: '颜色=浅色', effect: -1),
        BodyTypeRule(gender: 'female', bodyType: '梨形', slot: 'bottom', attribute: '版型=阔腿/A字', effect: 1),
        BodyTypeRule(gender: 'female', bodyType: '矩形', slot: '任意', attribute: '收腰/高腰', effect: 1),
        BodyTypeRule(gender: 'female', bodyType: '倒三角', slot: 'bottom', attribute: '版型=阔腿/A字', effect: 1),
        BodyTypeRule(gender: 'male', bodyType: '倒三角', slot: 'bottom', attribute: '版型=直筒/微阔', effect: 1),
      ];
}
