import 'package:flutter/material.dart';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TelaControler());
  }
}

class TelaControler extends StatefullWidget {
  @override
  _TelaControlerState createState() => _TelaControlerState();
}

class _TelaControlerState extends State<TelaControler> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Exemplo Simples")),
      body: Column(
        children: [
          TextField(controller: controller),

          ElevatedButton(
            onPressed: () {
              print(controller.text);
            },
            child: Text("Mostrar"),
          ),
        ],
      ),
    );
  }
}