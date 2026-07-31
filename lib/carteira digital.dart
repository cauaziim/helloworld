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
      home: Scaffold(
        appBar: AppBar(title: const Text("Carteira Digital")),
        body: Center(
          child: SingleChildScrollView( // pesquisei oque seria SingleChildScrollView e ele é um widget que permite rolar seu conteúdo quando ele ultrapassa os limites da tela
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [



                // CARTÃO 1


                Container(
                  height: 200,
                  width: 350,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
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
                        children: const [
                          Text("Banco SESI",
                              style: TextStyle(color: Colors.white)),
                          Icon(Icons.sim_card,
                              size: 40, color: Colors.white),
                        ],
                      ),
                      const Text(
                        "1234 5678 9012 3456",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("NOME",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10)),
                              Text("Davi Antonio Santos",
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("VALIDADE",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10)),
                              Text("12/30",
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),



                // CARTÃO 2



                Container(
                  height: 200,
                  width: 350,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
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
                        children: const [
                          Text("Banco Tech",
                              style: TextStyle(color: Colors.white)),
                          Icon(Icons.sim_card,
                              size: 40, color: Colors.white),
                        ],
                      ),
                      const Text(
                        "9876 5432 1098 7654",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("NOME",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10)),
                              Text("Davi Antonio Santos",
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("VALIDADE",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10)),
                              Text("08/29",
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),



                // CARTÃO 3



                Container(
                  height: 200,
                  width: 350,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple,
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
                        children: const [
                          Text("Banco Digital X",
                              style: TextStyle(color: Colors.white)),
                          Icon(Icons.sim_card,
                              size: 40, color: Colors.white),
                        ],
                      ),
                      const Text(
                        "1111 2222 3333 4444",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("NOME",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10)),
                              Text("Davi Antonio Santos",
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("VALIDADE",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10)),
                              Text("01/28",
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}