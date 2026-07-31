import 'package:flutter/material.dart';

void main() {
  runApp(MeuApp());
}

class MeuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TelaTeclados(),
    );
  }
}

class TelaTeclados extends StatelessWidget {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final idadeController = TextEditingController();
  final telefoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tipos de Teclados"),
      ),

      body: Padding(
        padding: EdgeInsets.all(16),

        child: Column(
          children: [

            // Campo Nome
            TextField(
              controller: nomeController,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                labelText: "Nome",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            // Campo Email
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            // Campo Idade
            TextField(
              controller: idadeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Idade",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            // Campo Telefone
            TextField(
              controller: telefoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Telefone",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            // Botão
            ElevatedButton(
              onPressed: () {

                print("Nome: ${nomeController.text}");
                print("Email: ${emailController.text}");
                print("Idade: ${idadeController.text}");
                print("Telefone: ${telefoneController.text}");

              },

              child: Text("Mostrar Dados"),
            ),
          ],
        ),
      ),
    );
  }
}