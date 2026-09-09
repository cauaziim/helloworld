import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
      title: 'Meu mapa',
      home: const MapaPage(),
    );
  }
}

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final MapController _mapController = MapController();

  LatLng? _localizacaoAtual;
  bool _carregando = true;
  bool _atualizando = false;

  @override
  void initState() {
    super.initState();
    _iniciarLocalizacao();
  }

  // Inicia a localização
  Future<void> _iniciarLocalizacao() async {
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      setState(() {
        _carregando = false;
      });
      return;
    }

    LocationPermission permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      setState(() {
        _carregando = false;
      });
      return;
    }

    await _atualizarLocalizacao();

    // Continua acompanhando a localização
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position posicao) {
      final novaLocalizacao = LatLng(
        posicao.latitude,
        posicao.longitude,
      );

      setState(() {
        _localizacaoAtual = novaLocalizacao;
      });
    });
  }

  // Função para atualizar a localização manualmente
  Future<void> _atualizarLocalizacao() async {
    setState(() {
      _atualizando = true;
    });

    try {
      Position posicao = await Geolocator.getCurrentPosition();

      final novaLocalizacao = LatLng(
        posicao.latitude,
        posicao.longitude,
      );

      setState(() {
        _localizacaoAtual = novaLocalizacao;
        _carregando = false;
        _atualizando = false;
      });

      // Centraliza o mapa na nova localização
      _mapController.move(
        novaLocalizacao,
        16,
      );

      // Mostra mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localização atualizada!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _atualizando = false;
        _carregando = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar a localização.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha localização'),
      ),

      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,

            options: const MapOptions(
              initialCenter: LatLng(
                -21.442010,
                -47.009005,
              ),
              initialZoom: 13,
            ),

            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.mapa_flutter',
              ),

              MarkerLayer(
                markers: [
                  if (_localizacaoAtual != null)
                    Marker(
                      point: _localizacaoAtual!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color.fromARGB(255, 89, 205, 40),
                        size: 55,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Indicador de carregamento inicial
          if (_carregando)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Botão para atualizar localização
          Positioned(
            right: 20,
            bottom: 90,
            child: FloatingActionButton(
              onPressed: _atualizando
                  ? null
                  : () {
                      _atualizarLocalizacao();
                    },
              child: _atualizando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.refresh),
            ),
          ),

          // Botão para voltar para minha localização
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () {
                if (_localizacaoAtual != null) {
                  _mapController.move(
                    _localizacaoAtual!,
                    16,
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
