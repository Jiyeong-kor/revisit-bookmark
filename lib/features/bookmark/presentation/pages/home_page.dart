import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: const Center(
        child: Text('북마크를 추가해보세요.'),
      ),
    );
  }
}
