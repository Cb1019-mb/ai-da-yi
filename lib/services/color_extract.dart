import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 提取出的主色：HEX + 面积占比(0-1)
class DominantColor {
  final String hex;
  final double ratio;
  const DominantColor(this.hex, this.ratio);
}

/// 从图片字节提取主色（直方图量化法，纯本地、无需模型）
/// [k] 返回颜色数，[levels] 每通道量化级数（2-8）
List<DominantColor> extractDominantColors(
  Uint8List bytes, {
  int k = 3,
  int levels = 5,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return const [];

  final shift = 8 - levels;
  final mask = (1 << levels) - 1;
  final histogram = <int, int>{};
  var total = 0;

  for (final pixel in decoded) {
    if (pixel.a < 10) continue; // 跳过透明像素
    final r = pixel.r.toInt() >> shift;
    final g = pixel.g.toInt() >> shift;
    final b = pixel.b.toInt() >> shift;
    final key = (r << (2 * levels)) | (g << levels) | b;
    histogram[key] = (histogram[key] ?? 0) + 1;
    total++;
  }

  if (total == 0) return const [];

  final entries = histogram.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final half = shift > 0 ? (1 << (shift - 1)) : 0;
  final result = <DominantColor>[];
  for (final e in entries.take(k)) {
    final r = (e.key >> (2 * levels)) & mask;
    final g = (e.key >> levels) & mask;
    final b = e.key & mask;
    final hex = '#${_hex((r << shift) + half)}'
        '${_hex((g << shift) + half)}'
        '${_hex((b << shift) + half)}';
    result.add(DominantColor(hex, e.value / total));
  }
  return result;
}

String _hex(int v) {
  final c = v.clamp(0, 255).toInt();
  return c.toRadixString(16).padLeft(2, '0');
}
