import 'package:flutter/material.dart';

void main() => runApp(const MeuApp());

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('AlertDialog'), titleTextStyle: const TextStyle(color: Colors.white), backgroundColor: Colors.purple),
          body: Center(
            child: ElevatedButton(
              child: const Text('Abrir'),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text ('Avisos'),
                  content: const Text('Item adicionado!'),
                  actions:[
                    TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('OK'))
                  ]
                )
              ),
            ),
          ),
        ),
      ),
    );
  }
}