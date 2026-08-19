import 'package:flutter/material.dart';

void main() {
  runApp(const MyGamesApp());
}

class Jogo {
  String nome;
  bool jogado;
  bool favorito;

  Jogo({required this.nome, this.jogado = false, this.favorito = false});
}

class MyGamesApp extends StatelessWidget {
  const MyGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "polystation",

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),

        useMaterial3: true,
      ),

      home: const Principal(),
    );
  }
}

class Principal extends StatefulWidget {
  const Principal({super.key});

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  int index = 0;

  final pesquisa = TextEditingController();

  final List<Jogo> jogos = [
    Jogo(nome: "Minecraft"),

    Jogo(nome: "GTA V"),

    Jogo(nome: "Fortnite"),

    Jogo(nome: "Valorant"),

    Jogo(nome: "Rocket League"),

    Jogo(nome: "EA Sports FC 25"),

    Jogo(nome: "God of War"),

    Jogo(nome: "Red Dead Redemption 2"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("polystation"), centerTitle: true),

      body: telas()[index],

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,

        onDestinationSelected: (valor) {
          setState(() {
            index = valor;
          });
        },

        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Inicio"),

          NavigationDestination(
            icon: Icon(Icons.sports_esports),

            label: "Jogos",
          ),

          NavigationDestination(icon: Icon(Icons.favorite), label: "Favoritos"),

          NavigationDestination(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  List<Widget> telas() {
    return [inicio(), jogosTela(), favoritos(), perfil()];
  }

  Widget inicio() {
    int jogados = jogos.where((j) => j.jogado).length;

    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Bem vindo ao polystation",

            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Text(
            "Jogos jogados: $jogados/${jogos.length}",

            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 20),

          LinearProgressIndicator(value: jogados / jogos.length, minHeight: 10),
        ],
      ),
    );
  }

  Widget jogosTela() {
    List<Jogo> filtrados = jogos.where((j) {
      return j.nome.toLowerCase().contains(pesquisa.text.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),

          child: TextField(
            controller: pesquisa,

            onChanged: (valor) {
              setState(() {});
            },

            decoration: InputDecoration(
              hintText: "Pesquisar jogo",

              prefixIcon: const Icon(Icons.search),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: filtrados.length,

            itemBuilder: (context, i) {
              Jogo jogo = filtrados[i];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),

                child: ListTile(
                  title: Text(jogo.nome),

                  leading: const Icon(Icons.gamepad),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      IconButton(
                        icon: Icon(
                          jogo.favorito
                              ? Icons.favorite
                              : Icons.favorite_border,

                          color: Colors.red,
                        ),

                        onPressed: () {
                          setState(() {
                            jogo.favorito = !jogo.favorito;
                          });
                        },
                      ),

                      Checkbox(
                        value: jogo.jogado,

                        onChanged: (valor) {
                          setState(() {
                            jogo.jogado = valor!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget favoritos() {
    List<Jogo> lista = jogos.where((j) => j.favorito).toList();

    if (lista.isEmpty) {
      return const Center(child: Text("Nenhum favorito"));
    }

    return ListView(
      children: lista
          .map(
            (j) => ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),

              title: Text(j.nome),
            ),
          )
          .toList(),
    );
  }

  Widget perfil() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          CircleAvatar(radius: 45, child: Icon(Icons.person, size: 50)),

          SizedBox(height: 15),

          Text(
            "Cauãzinho",

            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
