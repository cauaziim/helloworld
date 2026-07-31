import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ContadorTela(),
    );
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
      appBar: AppBar(
        title: const Text("APLICATIVO DE CURTIDAS"), centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 80, color: Colors.red),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            Text(
              "Curtidas: $contador",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: incrementar,
              style : ElevatedButton.styleFrom(

              ),
              child: const Text('Curtir'),
            ),
          ],
        ),
      ),
    );
  }
}