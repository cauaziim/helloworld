import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Overflow Example")),
        body: Column(
          children: [
            for (int i = 0; i < 10; i++)
              Container(
                margin: EdgeInsets.all(10),
                height: 80,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }
}