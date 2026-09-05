import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'color_extract.dart';

export 'color_extract.dart' show DominantColor;

/// 取色结果：提取出的候选主色 + 保存的图片路径
class PhotoColorResult {
  final List<DominantColor> colors;
  final String? imagePath;
  const PhotoColorResult(this.colors, this.imagePath);
}

/// 从相册选图并提取主色（无需相机权限）
Future<PhotoColorResult?> pickFromGallery() => _pick(ImageSource.gallery);

/// 拍照并提取主色
Future<PhotoColorResult?> pickFromCamera() => _pick(ImageSource.camera);

Future<PhotoColorResult?> _pick(ImageSource source) async {
  final picked = await ImagePicker()
      .pickImage(source: source, imageQuality: 85, maxWidth: 1080);
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  final colors = extractDominantColors(Uint8List.fromList(bytes), k: 3);

  // 保存一份到应用文档目录，作为单品图
  String? savedPath;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file =
        File('${dir.path}/item_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(bytes);
    savedPath = file.path;
  } catch (e) {
    debugPrint('[爱搭衣] 保存单品图片失败: $e');
  }

  return PhotoColorResult(colors, savedPath);
}
