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
        appBar: AppBar(
          title: const Text("Exemplo Column"),
        ),
        body: Center( // <- tirei o const aqui
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 50),
              const Text(
                "Flutter Layout",
                style: TextStyle(fontSize: 24),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text("Clique Aqui"),
              )
            ],
          ),
        ),
      ),
    );
  }
}