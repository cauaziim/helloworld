import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ContadorTela());
  }
}
class ContadorTela extends StatefulWidget {
  const ContadorTela({super.key});

  @override
  State<ContadorTela> createState() => _ContadorTelaState();
}

class _ContadorTelaState extends State<ContadorTela> {
  int contador = 0;

  void incrementar() {
    setState(() {
      contador++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Exemplo setState")),
      body: Center(
        child: Text("Contador: $contador", style: TextStyle(fontSize: 30)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: incrementar,
        child: Icon(Icons.add),
          ),
        );
  }
}