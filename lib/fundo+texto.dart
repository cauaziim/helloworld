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
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/akirinha_mexicano.jpg'),
              fit: BoxFit.fitWidth,
            ),
          ),
          child: Center(
            child: Text(
              'SENAI',
              style: TextStyle(
                fontSize: 30,
                color: Color.fromARGB(255, 1, 1, 1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}