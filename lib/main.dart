import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Importa las opciones generadas por FlutterFire
import 'screens/loading_screen.dart';

void main() async {
  // Asegura la inicialización de Flutter antes de llamar código nativo (Firebase)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const GameOnApp());
}

class GameOnApp extends StatelessWidget {
  const GameOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameOn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        fontFamily: 'Inter',
      ),
      home: const LoadingScreen(), // Llamamos a la pantalla de carga correcta
    );
  }
}