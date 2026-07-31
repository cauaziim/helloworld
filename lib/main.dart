import 'package:flutter/material.dart';

void main() {
  runApp(const LoginApp());
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    double largura = MediaQuery.of(context).size.width;
    double altura = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        // SafeArea
        child: SingleChildScrollView(
          // Scroll (evita overflow)
          child: Container(
            width: largura,
            constraints: BoxConstraints(minHeight: altura),
            padding: EdgeInsets.symmetric(horizontal: largura * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle,
                  size: largura * 0.25,
                  color: Colors.blue,
                ),

                Text(
                  "Login",
                  style: TextStyle(
                    fontSize: largura * 0.08,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: altura * 0.05),

                TextField(
                  decoration: InputDecoration(
                    labelText: "Usuário",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                SizedBox(height: altura * 0.02),

                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                SizedBox(height: altura * 0.04),

                //Botão
                SizedBox(
                  //pega a largura TODA da tela :D
                  width: double.infinity,
                  height: altura * 0.07,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text(
                      "Entrar",
                      style: TextStyle(fontSize: largura * 0.045),
                    ),
                  ),
                ),

                SizedBox(height: altura * 0.4),

                Text(
                  "Esqueceu a senha?",
                  style: TextStyle(fontSize: largura * 0.035),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
