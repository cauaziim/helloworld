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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             const Text("Bem-Vindo ", style: TextStyle(fontSize: 24)),
             const SizedBox(height: 20),
             Image.asset('assets/images/akirinha_mexicano.jpg'),
          ]
          ),
        ),
      ),
    );
  }
}