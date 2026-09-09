import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Qual lugar está mais perto?',
      home: const LocalizacaoPage(),
    );
  }
}

class LocalizacaoPage extends StatefulWidget {
  const LocalizacaoPage({super.key});

  @override
  State<LocalizacaoPage> createState() => _LocalizacaoPageState();
}

class _LocalizacaoPageState extends State<LocalizacaoPage> {
  String resultado = 'Clique no botão para calcular a distância';

  // COORDENADAS DA CASA
  double latitudeCasa = -21.442010;
  double longitudeCasa = -47.009005;

  Future<void> calcularDistancia() async {
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      setState(() {
        resultado = 'Ative o GPS do celular.';
      });
      return;
    }

    LocationPermission permissao =
        await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied) {
      setState(() {
        resultado = 'Permissão de localização negada.';
      });
      return;
    }

    if (permissao == LocationPermission.deniedForever) {
      setState(() {
        resultado =
            'A permissão foi negada permanentemente. Ative nas configurações.';
      });
      return;
    }

    Position posicaoAtual =
        await Geolocator.getCurrentPosition();

    double distancia = Geolocator.distanceBetween(
      posicaoAtual.latitude,
      posicaoAtual.longitude,
      latitudeCasa,
      longitudeCasa,
    );

    double distanciaKm = distancia / 1000;

    setState(() {
      resultado =
          'Distância até sua casa: ${distanciaKm.toStringAsFixed(2)} km';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qual lugar está mais perto?'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 90,
                color: Colors.blue,
              ),

              const SizedBox(height: 20),

              const Text(
                'Distância entre a escola e minha casa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                resultado,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: calcularDistancia,
                child: const Text(
                  'Calcular distância',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}