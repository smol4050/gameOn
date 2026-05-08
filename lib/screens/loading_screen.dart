import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_navigation_screen.dart';
import 'login_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      // Esperamos 2 segundos para mostrar el logo
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;

      // Verificamos si Firebase ya tiene un usuario activo
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Sesión activa -> Al Home (MainNavigation)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        // No hay sesión -> Al Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // 🔹 SI HAY UN ERROR (ej. Firebase no inicializado), LO ATRAPAMOS AQUÍ
      debugPrint("Error crítico en LoadingScreen: $e");
      
      if (mounted) {
        // Forzamos la navegación al Login para que no se quede trabado
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 100, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Game On',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}