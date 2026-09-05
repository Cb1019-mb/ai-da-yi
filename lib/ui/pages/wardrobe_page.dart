import 'dart:io';

import 'package:flutter/material.dart';

import '../../engine/matching_engine.dart';
import '../../models/models.dart';
import '../../services/photo_color.dart';
import '../../state/wardrobe_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class WardrobePage extends StatelessWidget {
  const WardrobePage({super.key});

  static const _slotLabels = {
    'top': '上装',
    'bottom': '下装',
    'dress': '连衣裙',
    'shoes': '鞋履',
    'accessory': '配饰',
  };

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const AddItemSheet(),
    );
  }

  /// 衣橱利用率：出现在搭配结果中的单品占比，列出从未被搭过的单品
  Widget _usageCard(WardrobeStore store) {
    final items = store.items;
    final used = items
        .where((i) => store.usedFingerprints.contains(itemFingerprint(i)))
        .length;
    final unused = items
        .where((i) => !store.usedFingerprints.contains(itemFingerprint(i)))
        .toList();
    final rate = items.isEmpty ? 0.0 : used / items.length;
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('衣橱利用率',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
          Text('${(rate * 100).toStringAsFixed(0)}% · $used/${items.length} 件出现过',
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.line,
            color: AppColors.clay,
          ),
        ),
        if (unused.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('${unused.length} 件从未出现在搭配结果中',
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final i in unused.take(12))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    ColorDot(hex: i.colorMain, size: 12),
                    const SizedBox(width: 4),
                    Text(i.categoryName,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.ink)),
                  ]),
                ),
            ],
          ),
          if (unused.length > 12)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('…等共 ${unused.length} 件',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.muted)),
            ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = WardrobeStore.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Row(children: [
                    const Expanded(
                      child: SectionHeader(eyebrow: 'WARDROBE', title: '我的衣橱'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openAddSheet(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加'),
                    ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(child: _usageCard(store)),
              ),
              if (store.items.isEmpty)
                const SliverToBoxAdapter(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList.separated(
                    itemCount: store.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = store.items[i];
                      return _ItemTile(
                        item: item,
                        slotLabel: _slotLabels[item.slot] ?? item.slot,
                        onDelete: () => store.removeItem(item),
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 64, horizontal: AppSpacing.lg),
      child: Column(children: [
        Icon(Icons.checkroom,
            size: 48, color: AppColors.clay.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        const Text('衣橱还是空的',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        const SizedBox(height: 6),
        const Text('点击右上角「添加」录入你的第一件单品',
            style: TextStyle(fontSize: 13, color: AppColors.muted)),
      ]),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final WardrobeItem item;
  final String slotLabel;
  final VoidCallback onDelete;
  const _ItemTile(
      {required this.item, required this.slotLabel, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final meta = [item.fit, ...item.styleTags]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        if (item.imagePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(item.imagePath!),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  ColorDot(hex: item.colorMain, size: 40),
            ),
          )
        else
          ColorDot(hex: item.colorMain, size: 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(item.categoryName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
              const SizedBox(width: 8),
              _MiniTag(slotLabel),
            ]),
            const SizedBox(height: 4),
            Text(meta,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
        ),
      ]),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.claySoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.clayInk,
                fontWeight: FontWeight.w600)),
      );
}

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  String _slot = 'top';
  final _nameCtrl = TextEditingController();
  String? _categoryName;
  Color _color = appPalette.first.color;
  String? _photoPath;
  List<DominantColor> _extracted = const [];
  String? _fit = '标准';
  String? _pattern;
  String? _material;
  String? _length;
  double _thickness = 3;
  double _formal = 3;
  double _exposure = 1;
  final Set<String> _seasons = {'春'};
  final Set<String> _styles = {};

  static const _slots = <(String, String)>[
    ('top', '上装'),
    ('bottom', '下装'),
    ('dress', '连衣裙'),
    ('shoes', '鞋履'),
    ('accessory', '配饰'),
  ];
  // 各部位的选项配置：空列表 = 该部位不显示该字段
  static const _patternOptions = <String, List<String>>{
    'top': ['纯色', '条纹', '格纹', '印花', '波点', '拼接', '迷彩', '牛仔水洗'],
    'bottom': ['纯色', '条纹', '格纹', '印花', '波点', '拼接', '迷彩', '牛仔水洗'],
    'dress': ['纯色', '条纹', '格纹', '印花', '波点', '碎花', '扎染'],
    'shoes': ['纯色', '拼接', '印花'],
    'accessory': ['纯色', '格纹', '印花', '波点', '流苏'],
  };
  static const _materialOptions = <String, List<String>>{
    'top': ['棉', '麻', '真丝', '羊毛', '针织', '雪纺', '牛仔', '涤纶', '呢料'],
    'bottom': ['棉', '麻', '真丝', '羊毛', '牛仔', '涤纶', '呢料', '灯芯绒', '皮革'],
    'dress': ['棉', '麻', '真丝', '雪纺', '针织', '涤纶'],
    'shoes': ['皮革', '漆皮', '麂皮', '帆布', '网面', '橡胶', '针织'],
    'accessory': ['真丝', '皮革', '金属', '草编', '珍珠', '羊毛', '棉麻'],
  };
  static const _lengthOptions = <String, List<String>>{
    'top': ['短款', '常规', '中长', '长款'],
    'bottom': ['短款', '常规', '七分', '九分', '长款'],
    'dress': ['短款', '及膝', '中长', '长款', '及踝'],
    'shoes': ['35', '36', '37', '38', '39', '40', '41', '42', '43', '44'],
    'accessory': [],
  };
  static const _fitOptions = <String, List<String>>{
    'top': ['修身', '标准', '宽松', 'oversize', '直筒'],
    'bottom': ['修身', '标准', '宽松', '直筒', '微阔', '阔腿', 'A字'],
    'dress': ['修身', '标准', '宽松', '收腰', 'A字'],
    'shoes': [],
    'accessory': [],
  };

  List<String> get _patterns => _patternOptions[_slot] ?? const [];
  List<String> get _materials => _materialOptions[_slot] ?? const [];
  List<String> get _lengths => _lengthOptions[_slot] ?? const [];
  List<String> get _fits => _fitOptions[_slot] ?? const [];
  bool get _isShoes => _slot == 'shoes';

  /// 部位 → 品类树大类名
  static const _slotBigNames = {
    'top': '上装',
    'bottom': '下装',
    'dress': '连衣裙',
    'shoes': '鞋靴',
    'accessory': '配饰',
  };

  /// 当前部位 + 性别下的可选品类（来自知识库品类树）
  List<String> _categoryOptions() {
    final store = WardrobeStore.instance;
    final bigName = _slotBigNames[_slot];
    if (bigName == null) return const [];
    final parentIds = store.categories
        .where((c) =>
            c.parentId == null &&
            c.name == bigName &&
            c.gender == store.profile.gender)
        .map((c) => c.id)
        .toSet();
    return store.categories
        .where((c) => c.parentId != null && parentIds.contains(c.parentId))
        .map((c) => c.name)
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggle(Set<String> set, String v) {
    if (set.contains(v)) {
      set.remove(v);
    } else {
      set.add(v);
    }
  }

  Future<void> _pickColor(bool fromCamera) async {
    final result =
        fromCamera ? await pickFromCamera() : await pickFromGallery();
    if (result == null || !mounted) return;
    setState(() {
      _photoPath = result.imagePath;
      _extracted = result.colors;
      // 自动提取：取第一大主色
      if (result.colors.isNotEmpty) {
        _color = hexColor(result.colors.first.hex);
      }
    });
  }

  void _save() {
    final name =
        _categoryName == '自定义' ? _nameCtrl.text.trim() : (_categoryName ?? '');
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择或输入品类名称')));
      return;
    }
    final store = WardrobeStore.instance;
    final matched = store.categories
        .where((c) => c.name == name && c.gender == store.profile.gender)
        .toList();
    store.addItem(WardrobeItem(
      categoryId: matched.isNotEmpty ? matched.first.id : null,
      slot: _slot,
      gender: store.profile.gender,
      categoryName: name,
      colorMain: colorToHex(_color),
      fit: _fit,
      pattern: _pattern,
      material: _material,
      length: _length,
      thickness: _thickness.round(),
      formalLevel: _formal.round(),
      exposure: _exposure.round(),
      season: _seasons.toList(),
      styleTags: _styles.toList(),
      imagePath: _photoPath,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = WardrobeStore.instance;
    final gender = store.profile.gender;
    final styleNames = store.styles
        .where((s) => s.gender == gender || s.gender == 'unisex')
        .map((s) => s.name)
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.md),
          const Text('添加单品',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: AppSpacing.md),
          const _Label('部位'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _slots)
                TagChip(
                    label: s.$2,
                    selected: _slot == s.$1,
                    onTap: () => setState(() {
                          _slot = s.$1;
                          _categoryName = null;
                          // 部位切换后，清掉不适用的已选项
                          if (!_patterns.contains(_pattern)) _pattern = null;
                          if (!_materials.contains(_material)) _material = null;
                          if (!_lengths.contains(_length)) _length = null;
                          if (!_fits.contains(_fit)) {
                            _fit = _fits.isNotEmpty ? _fits.first : null;
                          }
                        })),
            ],
          ),
          const SizedBox(height: 16),
          const _Label('品类'),
          const SizedBox(height: 8),
          if (_categoryOptions().isEmpty)
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: '如：针织衫',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _categoryOptions())
                  TagChip(
                      label: c,
                      selected: _categoryName == c,
                      onTap: () => setState(() => _categoryName = c)),
                TagChip(
                    label: '自定义',
                    selected: _categoryName == '自定义',
                    onTap: () => setState(() => _categoryName = '自定义')),
              ],
            ),
            if (_categoryName == '自定义') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: '输入自定义品类',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          const _Label('图片取色'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickColor(false),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('相册选图'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickColor(true),
                icon: const Icon(Icons.photo_camera, size: 18),
                label: const Text('拍照'),
              ),
            ),
          ]),
          if (_photoPath != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_photoPath!),
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 96, height: 96),
              ),
            ),
          ],
          if (_extracted.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('提取色（点选为主色）',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.muted)),
                for (final dc in _extracted)
                  GestureDetector(
                    onTap: () => setState(() => _color = hexColor(dc.hex)),
                    child: ColorDot(hex: dc.hex, size: 30),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const _Label('颜色'),
            Text(colorToHex(_color),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
          const SizedBox(height: 8),
          for (final group in groupedPalette().entries) ...[
            Text(group.key,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final sw in group.value)
                  _Swatch(
                    swatch: sw,
                    selected: _color == sw.color,
                    onTap: () => setState(() => _color = sw.color),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          const _Label('图案'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TagChip(
                  label: '不限',
                  selected: _pattern == null,
                  onTap: () => setState(() => _pattern = null)),
              for (final p in _patterns)
                TagChip(
                    label: p,
                    selected: _pattern == p,
                    onTap: () => setState(() => _pattern = p)),
            ],
          ),
          const SizedBox(height: 16),
          const _Label('材质'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TagChip(
                  label: '不限',
                  selected: _material == null,
                  onTap: () => setState(() => _material = null)),
              for (final m in _materials)
                TagChip(
                    label: m,
                    selected: _material == m,
                    onTap: () => setState(() => _material = m)),
            ],
          ),
          if (_lengths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Label(_isShoes ? '鞋码' : '长度'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TagChip(
                    label: '不限',
                    selected: _length == null,
                    onTap: () => setState(() => _length = null)),
                for (final l in _lengths)
                  TagChip(
                      label: l,
                      selected: _length == l,
                      onTap: () => setState(() => _length = l)),
              ],
            ),
          ],
          if (_fits.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _Label('版型'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _fits)
                  TagChip(
                      label: f,
                      selected: _fit == f,
                      onTap: () => setState(() => _fit = f)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const _Label('季节'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in const ['春', '夏', '秋', '冬'])
                TagChip(
                    label: s,
                    selected: _seasons.contains(s),
                    onTap: () => setState(() => _toggle(_seasons, s))),
            ],
          ),
          const SizedBox(height: 16),
          const _Label('风格标签'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in styleNames)
                TagChip(
                    label: s,
                    selected: _styles.contains(s),
                    onTap: () => setState(() => _toggle(_styles, s))),
            ],
          ),
          const SizedBox(height: 16),
          if (_slot != 'accessory')
            _Slider(
                label: '厚度',
                value: _thickness,
                min: 1,
                max: 5,
                onChanged: (v) => setState(() => _thickness = v)),
          _Slider(
              label: '正式度',
              value: _formal,
              min: 1,
              max: 5,
              onChanged: (v) => setState(() => _formal = v)),
          if (_slot != 'accessory')
            _Slider(
                label: '露肤度',
                value: _exposure,
                min: 0,
                max: 5,
                onChanged: (v) => setState(() => _exposure = v)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.clay,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('保存'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final PaletteSwatch swatch;
  final bool selected;
  final VoidCallback onTap;
  const _Swatch({required this.swatch, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: swatch.color,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? AppColors.ink : Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink));
}

class _Slider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  const _Slider(
      {required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
            Text('${value.round()}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ]),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
            activeColor: AppColors.clay,
          ),
        ],
      );
}
