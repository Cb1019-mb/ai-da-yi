import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'ui/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AiDaYiApp());
}

class AiDaYiApp extends StatelessWidget {
  const AiDaYiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '爱搭衣',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeShell(),
    );
  }
}
