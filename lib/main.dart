import 'package:flutter/material.dart';

void main() {
  runApp(const TapestryApp());
}

class TapestryApp extends StatelessWidget {
  const TapestryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tapestry',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const PlaceholderScreen(),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Tapestry',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
