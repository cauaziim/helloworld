import 'package:flutter/material.dart';

void main() => runApp(const MeuApp());

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

@override
Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text ('SnackBar'),
          backgroundColor: Colors.purple,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20)
        ),
        body: Center(
          child: const Text('Salvar'),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar (content: Text ('Produto salvo com sucesso!')),
          ),
        )
      )
    )
  );
}
}