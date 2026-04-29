import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'login_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Navega al login después de 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100),
            
            // Título
            Text(
              'Game On',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 64,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            
            SizedBox(height: 8),
            
            // Subtítulo
            Text(
              'Encuentra tu partido',
              style: TextStyle(
                color: Color(0xFF4A5565),
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            
            SizedBox(height: 50),
            
            // Imagen
            Container(
              width: 245,
              height: 435,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage("https://placehold.co/245x435"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            SizedBox(height: 50),
            
            // Indicador de carga
            Container(
              width: 143,
              height: 27,
              decoration: ShapeDecoration(
                color: Color(0xFFD9D9D9),
                shape: StadiumBorder(),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}