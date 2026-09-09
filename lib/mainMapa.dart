import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

class MapaPage extends StatelessWidget {
  const MapaPage({super.key});


  @override
   Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu mapa')),
      
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(-21.442010, -47.009005),
          initialZoom: 13,
        ),

        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mapa_flutter',
          ),
        ],
      ),
    );
   }
} 