import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Carteira Digital",
      home: CarteiraDigital(),
    );
  }
}

class CarteiraDigital extends StatelessWidget {
  const CarteiraDigital({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Carteira Digital"),
      centerTitle: true,
      ),

      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          CartaoBanco(
            corCartao: Colors.deepPurple,
            banco: "Banco SESI",
            numero: "1234 5678 9012 3456",
            nome: "Davi Antonio",
            validade: "12/30",
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class CartaoBanco extends StatelessWidget {
  final Color corCartao;
  final String banco;
  final String numero;
  final String nome;
  final String validade;

  const CartaoBanco({
    super.key,
    required this.corCartao,
    required this.banco,
    required this.numero,
    required this.nome,
    required this.validade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corCartao,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(banco, style: TextStyle(color: Colors.white)),
              Icon(Icons.contactless, size: 20, color: Colors.white),
            ],
          ),

          Icon(Icons.sim_card, size: 40, color: Colors.amber),
          
          Text(numero, style: TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              
              Text(nome, style: TextStyle(color: Colors.white)),
              Text(validade, style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}