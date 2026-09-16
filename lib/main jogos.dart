import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const GameStoreApp());
}

class GameStoreApp extends StatelessWidget {
  const GameStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'sabino Store',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _paginaAtual = 0;

  // Player do áudio
  final AudioPlayer player = AudioPlayer();

  final List<Map<String, dynamic>> jogos = [
    {
      "nome": "GTA V",
      "preco": "R\$ 89,90",
      "imagem":
          "https://upload.wikimedia.org/wikipedia/en/a/a5/Grand_Theft_Auto_V.png",
    },
    {
      "nome": "Minecraft",
      "preco": "R\$ 99,90",
      "imagem":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQEEvFIKXrKOJuOYTRQisa_w-digVJN3v7-RA&s",
    },
    {
      "nome": "EA SPORTS FC",
      "preco": "R\$ 349,90",
      "imagem":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTX-8VqM75SutGX4BQSF67pwTScwnXl6zKznA&s",
    },
    {
      "nome": "Free Fire",
      "preco": "Grátis",
      "imagem":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTl8ChEz5aiEtyp5HkGleh0-J3JH8tUGCF3Hw&s",
    },
    {
      "nome": "Fortnite",
      "preco": "Grátis",
      "imagem":
          "https://cdn.ome.lt/uploads/conteudo/fotos/FNBR_40-00_C7S2_EGS_Launcher_FN_Blade_2560x1440_2560x1440-325670227bc348a4a289570c1f099640.jpg",
    },
    {
      "nome": "Call of Duty",
      "preco": "R\$ 279,90",
      "imagem":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQWOzfw4UIlYMtY3GcUNK_wHrhProYeHEbEdQ&s",
    },
  ];

  final List<Map<String, dynamic>> carrinho = [];

  // Toca o som
  Future<void> tocarSom() async {
    await player.play(
      AssetSource('audio/toque.mp3'),
    );
  }

  // Calcula o valor total
  double calcularTotal() {
    double total = 0;

    for (var jogo in carrinho) {
      String preco = jogo["preco"];

      if (preco != "Grátis") {
        preco = preco
            .replaceAll("R\$", "")
            .replaceAll(".", "")
            .replaceAll(",", ".")
            .trim();

        total += double.tryParse(preco) ?? 0;
      }
    }

    return total;
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("🎮 Game Store"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),

      body: _buildBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaAtual,
        onTap: (index) {
          setState(() {
            _paginaAtual = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Início",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset),
            label: "Jogos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Carrinho",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_paginaAtual) {
      case 0:
        return telaInicio();

      case 1:
        return telaJogos();

      case 2:
        if (carrinho.isEmpty) {
          return const Center(
            child: Text(
              "🛒 Carrinho vazio",
              style: TextStyle(fontSize: 24),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: carrinho.length,
                itemBuilder: (context, index) {
                  final jogo = carrinho[index];

                  return Card(
                    color: Colors.grey.shade900,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          jogo["imagem"],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),

                      title: Text(
                        jogo["nome"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        jogo["preco"],
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            carrinho.removeAt(index);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Jogo removido do carrinho",
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  Text(
                    "Total da compra: R\$ ${calcularTotal().toStringAsFixed(2).replaceAll(".", ",")}",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),

                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Compra realizada! Total: R\$ ${calcularTotal().toStringAsFixed(2).replaceAll(".", ",")}",
                            ),
                          ),
                        );

                        setState(() {
                          carrinho.clear();
                        });
                      },

                      icon: const Icon(Icons.payment),
                      label: const Text("Finalizar Compra"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 3:
        return const Center(
          child: Text(
            "👤 Perfil",
            style: TextStyle(fontSize: 24),
          ),
        );

      default:
        return telaInicio();
    }
  }

  Widget telaInicio() {
    return const Center(
      child: Text(
        "Bem-vindo à Game Store 🎮",
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget telaJogos() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Pesquisar jogo...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jogos.length,

            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .63,
            ),

            itemBuilder: (context, index) {
              final jogo = jogos[index];

              return Card(
                color: Colors.grey.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),

                        child: Image.network(
                          jogo["imagem"],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(10),

                      child: Column(
                        children: [
                          Text(
                            jogo["nome"],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            jogo["preco"],
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,

                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),

                              onPressed: () async {
                                // Toca o som
                                await tocarSom();

                                // Adiciona ao carrinho
                                setState(() {
                                  carrinho.add(jogo);
                                });

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${jogo["nome"]} adicionado ao carrinho!",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },

                              icon: const Icon(
                                Icons.shopping_cart,
                              ),

                              label: const Text("Comprar"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}