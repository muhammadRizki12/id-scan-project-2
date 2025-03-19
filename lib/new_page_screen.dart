// screens/new_page_screen.dart
import 'package:flutter/material.dart';

class newPageScreen extends StatelessWidget {
  const newPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'selesai',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
