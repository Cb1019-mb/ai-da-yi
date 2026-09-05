import 'package:flutter/material.dart';

/// 全屏图片查看器：双指缩放 + 拖动查看细节
class ImageViewerPage extends StatelessWidget {
  final String assetPath;
  final String title;
  const ImageViewerPage({super.key, required this.assetPath, this.title = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: InteractiveViewer(
        panEnabled: true,
        maxScale: 5,
        child: Center(
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  size: 48, color: Colors.white38),
            ),
          ),
        ),
      ),
    );
  }
}
