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
      home: const CarteiraDigital(),
    );
  }
}

class CarteiraDigital extends StatelessWidget {
  const CarteiraDigital({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carteira Digital"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          CartaoBanco(
            corCartao: Colors.deepPurple,
            banco: "Banco SESI",
            numero: "1234 5678 9012 3456",
            nome: "Davi Antonio",
            validade: "12/30",
            bandeira: "visa",
          ),
          SizedBox(height: 20),

          CartaoBanco(
            corCartao: Colors.blue,
            banco: "Banco Digital",
            numero: "9876 5432 1098 7654",
            nome: "Davi Santos",
            validade: "08/28",
            bandeira: "mastercard",
          ),
          SizedBox(height: 20),

          CartaoBanco(
            corCartao: Colors.green,
            banco: "Banco XPTO",
            numero: "1111 2222 3333 4444",
            nome: "Davi A. Santos",
            validade: "05/27",
            bandeira: "outro",
          ),
          SizedBox(height: 20),

          CartaoBanco(
            corCartao: Colors.orange,
            banco: "Banco Inter",
            numero: "2222 3333 4444 5555",
            nome: "Davi Santos",
            validade: "09/29",
            bandeira: "mastercard",
          ),
          SizedBox(height: 20),

          CartaoBanco(
            corCartao: Colors.black,
            banco: "Banco Premium",
            numero: "9999 8888 7777 6666",
            nome: "Davi A Santos",
            validade: "03/31",
            bandeira: "visa",
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
  final String bandeira;

  const CartaoBanco({
    super.key,
    required this.corCartao,
    required this.banco,
    required this.numero,
    required this.nome,
    required this.validade,
    required this.bandeira,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 imagem LOCAL (do PC/projeto)
    Widget imagemBandeira;

    if (bandeira == "visa") {
      imagemBandeira = Image.asset(
        'assets/images/visa.png',
        width: 50,
      );
    } else if (bandeira == "mastercard") {
      imagemBandeira = Image.asset(
        'assets/images/mastercard.png',
        width: 50,
      );
      }else {
        imagemBandeira = const Icon(
          Icons.credit_card,
          color: Colors.white,
        );
      }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corCartao,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
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
            children: [
              Text(banco, style: const TextStyle(color: Colors.white)),
              const Spacer(),

              imagemBandeira,

              const Spacer(),
              const Icon(Icons.contactless, size: 20, color: Colors.white),
            ],
          ),

          const Icon(Icons.sim_card, size: 40, color: Colors.amber),

          Text(
            numero,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nome, style: const TextStyle(color: Colors.white)),
              Text(validade, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}