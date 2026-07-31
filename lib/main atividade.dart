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
        appBar: AppBar(title: const Text("Layout Quadrados")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quadrado azul (topo)
              Container(
                height: 100,
                width: 200,
                color: Colors.blue,
              ),

              const SizedBox(height: 20), // espaço vertical

              // Linha com vermelho e verde
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vermelho
                  Container(
                    height: 80,
                    width: 80,
                    color: Colors.red,
                  ),

                  const SizedBox(width: 20), // espaço horizontal

                  // Verde
                  Container(
                    height: 80,
                    width: 80,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}