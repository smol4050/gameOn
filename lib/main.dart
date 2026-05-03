import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
void main() {
  runApp(const GameOnApp());
}

class GameOnApp extends StatelessWidget {
  const GameOnApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game On',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Inter',
      ),
      home: const LoginScreen(), // Muestra el login
    );
  }
}