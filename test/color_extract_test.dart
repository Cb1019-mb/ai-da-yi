import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:ai_da_yi/services/color_extract.dart';

void main() {
  test('纯红图片提取主色为红色系', () {
    final image = img.Image(width: 20, height: 20);
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    final bytes = Uint8List.fromList(img.encodePng(image));

    final colors = extractDominantColors(bytes, k: 1);
    expect(colors, isNotEmpty);

    final hex = colors.first.hex.replaceAll('#', '');
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);
    expect(r, greaterThan(200));
    expect(g, lessThan(30));
    expect(b, lessThan(30));
    expect(colors.first.ratio, greaterThan(0.9));
  });
}
