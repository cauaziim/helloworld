import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Hello World App')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Flutter layout', style: TextStyle(fontSize: 24)),
              ElevatedButton(onPressed: () {}, child: Text('Click Aqui')),
            ],
          ),
        ),
      ),
    );
  }
}
