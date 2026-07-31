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
        appBar: AppBar(title: Text('Minha tela')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.thumb_up, size: 50, color: Colors.blue),
              Text(
                "D.S é o melhor curso de SESI?",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight(22),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  print("Usuario Clicou");
                },
                child: Text('Curtir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
