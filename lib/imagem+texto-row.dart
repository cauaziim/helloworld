import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Bem-Vindo ", style: TextStyle(fontSize: 24)),
              SizedBox(width: 20),
              Image(image: AssetImage('assets/images/akirinha_mexicano.jpg'), width: 100, height: 100),
            ],
          ),
        ),
      ),
    );
  }
}