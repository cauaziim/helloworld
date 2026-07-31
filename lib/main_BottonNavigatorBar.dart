import 'package:flutter/material.dart';

void main() => runApp(const MeuApp());

class MeuApp extends StatefulWidget {
  const MeuApp({super.key});

  @override
  State<MeuApp> createState() => _MeuAppState();
}

class _MeuAppState extends State<MeuApp> {
  int _aba = 0; 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('BottomNav'), backgroundColor: Colors.purple,
         titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20)),
        body: Center(child: Text('Aba atual: $_aba', style: const TextStyle(fontSize: 24))),
        
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _aba,
          onTap: (index) {
            print('Clicou na aba $index');
            setState(() => _aba = index);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil')
          ]
        ),
      ),
    );
  }
}