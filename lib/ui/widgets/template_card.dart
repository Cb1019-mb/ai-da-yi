import 'package:flutter/material.dart';

import '../../models/style_template.dart';
import '../../theme/app_theme.dart';
import 'common.dart';
import 'image_viewer.dart';

/// 风格模板卡片：展示示例搭配图 + 单品 + 一键加入衣橱
class TemplateCard extends StatelessWidget {
  final StyleTemplate template;
  final VoidCallback onAdd;
  const TemplateCard({super.key, required this.template, required this.onAdd});

  static const _slotLabels = {
    'top': '上装',
    'bottom': '下装',
    'dress': '连衣裙',
    'shoes': '鞋履',
    'accessory': '配饰',
  };

  void _openViewer(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ImageViewerPage(
        assetPath: 'assets/images/templates/${template.image}',
        title: '${template.name} · 示例搭配',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 完整展示原图（正方形不裁切），点击进入全屏查看
          GestureDetector(
            onTap: () => _openViewer(context),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    'assets/images/templates/${template.image}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.background,
                      child: const Center(
                        child: Icon(Icons.checkroom,
                            size: 40, color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.zoom_out_map,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${template.name} · 示例搭配',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 6),
                Text(template.description,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in template.items)
                      _TemplateItemChip(
                          slotLabel: _slotLabels[item.slot] ?? item.slot,
                          item: item),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onAdd,
                    child: const Text('一键加入衣橱'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateItemChip extends StatelessWidget {
  final String slotLabel;
  final StyleTemplateItem item;
  const _TemplateItemChip({required this.slotLabel, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(slotLabel,
            style: const TextStyle(
                fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        ColorDot(hex: item.colorMain, size: 14),
        const SizedBox(width: 6),
        Text(item.categoryName,
            style: const TextStyle(
                fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
