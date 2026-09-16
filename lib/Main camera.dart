import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Problemas do Dia a Dia',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? foto;

  Future<void> tirarFoto() async {
    final picker = ImagePicker();

    final imagem = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (imagem != null) {
      setState(() {
        foto = File(imagem.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Problemas do Dia a Dia'),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 20),

            const Icon(
              Icons.report_problem,
              size: 70,
              color: Colors.orange,
            ),

            const SizedBox(height: 15),

            const Text(
              'Registre um problema',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Tire uma foto de um problema encontrado '
              'no seu dia a dia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.shade200,
                ),

                child: foto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          foto!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera,
                              size: 60,
                              color: Colors.grey,
                            ),

                            SizedBox(height: 10),

                            Text(
                              'Nenhuma foto registrada',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: tirarFoto,

                icon: const Icon(
                  Icons.camera_alt,
                  size: 28,
                ),

                label: Text(
                  foto == null
                      ? 'TIRAR FOTO DO PROBLEMA'
                      : 'TIRAR OUTRA FOTO',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            if (foto != null)
              SizedBox(
                width: double.infinity,
                height: 50,

                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Problema registrado com sucesso!',
                        ),
                      ),
                    );
                  },

                  icon: const Icon(Icons.check),

                  label: const Text(
                    'REGISTRAR PROBLEMA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
