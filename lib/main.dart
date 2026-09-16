import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SensorPage(),
    );
  }
}

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  double x = 0;
  double y = 0;
  double z = 0;

  bool movimento = false;

  @override
  void initState() {
    super.initState();

    accelerometerEventStream().listen((event) {
      double aceleracao = sqrt(
        (event.x * event.x) +
        (event.y * event.y) +
        (event.z * event.z),
      );

      setState(() {
        x = event.x;
        y = event.y;
        z = event.z;

        // Detecta movimento
        if (aceleracao > 12) {
          movimento = true;
        } else {
          movimento = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector de Movimento'),
        centerTitle: true,
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Informação do movimento
            Icon(
              movimento ? Icons.directions_run : Icons.phone_android,
              size: 80,
            ),

            const SizedBox(height: 20),

            Text(
              movimento
                  ? 'MOVIMENTO DETECTADO!'
                  : 'Celular parado',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              'Valores do Acelerômetro',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'X: ${x.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22),
            ),

            Text(
              'Y: ${y.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22),
            ),

            Text(
              'Z: ${z.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 30),

            Text(
              movimento
                  ? 'O dispositivo está sendo movimentado.'
                  : 'Nenhum movimento detectado.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}