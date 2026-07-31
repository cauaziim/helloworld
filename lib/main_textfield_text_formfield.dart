import 'package:flutter/material.dart';

void main() {
  runApp(MeuApp());
}

class MeuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TelaComparacao(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TelaComparacao extends StatefulWidget {
  @override
  _TelaComparacaoState createState() => _TelaComparacaoState();
}

class _TelaComparacaoState extends State<TelaComparacao> {
  final controllerSimples = TextEditingController();
  final controllerForm = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("TextField vs TextFormField"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TEXTFIELD "COMUM" (SEM VALIDAÇÃO)

            Text("TextField (simples)"),

            SizedBox(height: 10),

            TextField(
              controller: controllerSimples,
              decoration: InputDecoration(
                labelText: "Digite algo",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                print("TextField: ${controllerSimples.text}");
              },
              child: Text("Mostrar TextField"),
            ),

            SizedBox(height: 30),

            // TEXTFORMFIELD (COM VALIDAÇÃO)

            Text("TextFormField (com validação)"),

            SizedBox(height: 10),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: controllerForm,
                    decoration: InputDecoration(
                      labelText: "Digite seu nome",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        print(
                          "TextFormField: ${controllerForm.text}",
                        );
                      }
                    },
                    child: Text("Validar Formulário"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}