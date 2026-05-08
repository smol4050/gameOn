import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_screen.dart';
import 'main_navigation_screen.dart'; // 🔹 Importamos el nuevo contenedor de navegación
import '../services/auth_service.dart';
import 'complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 🔹 CONTROLADORES DE TEXTO
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  // 🔹 LÓGICA DE GOOGLE LOGIN
  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService().signInWithGoogle();
      
      if (result != null) {
        User user = result['user'];
        bool isNewUser = result['isNewUser'];

        if (!mounted) return;

        if (isNewUser) {
          // Si es nuevo, va a completar Deporte y Nivel
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(
                uid: user.uid,
                name: user.displayName ?? '',
                email: user.email ?? '',
              ),
            ),
          );
        } else {
          // Si ya existe, va al Home (MainNavigationScreen)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión con Google: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 LÓGICA DE LOGIN CON EMAIL
  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService().loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        if (!mounted) return;
        // Si el login es exitoso, vamos al Home (MainNavigationScreen)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Error al iniciar sesión'), 
          backgroundColor: Colors.red
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        // 🔹 Agregamos SingleChildScrollView para evitar que el teclado tape los inputs
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: 390,
              // Eliminamos el height fijo para que se adapte al contenido
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),

                  // 🔹 TITLE
                  const Text(
                    'Game On',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Encuentra tu partido',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4A5565),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 🔹 EMAIL INPUT
                  _inputField(
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                  ),

                  const SizedBox(height: 16),

                  // 🔹 PASSWORD INPUT
                  _inputField(
                    hint: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscure: true,
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 16),

                  // 🔹 LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 REGISTER BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      // 🔹 NAVEGACIÓN A LA PANTALLA DE REGISTRO
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF364153),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 FORGOT PASSWORD
                  const Center(
                    child: Text(
                      'Olvidé mi contraseña',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔹 DIVIDER
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(color: Color(0xFFE5E7EB)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'O continúa con',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6A7282),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Color(0xFFE5E7EB)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 🔹 SOCIAL BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: _socialButton(
                          text: 'Google',
                          icon: Icons.g_mobiledata,
                          onTap: _isLoading ? null : _loginWithGoogle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _socialButton(
                          text: 'Apple',
                          icon: Icons.apple,
                          onTap: () {
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    bool obscure = false,
    required TextEditingController controller,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String text,
    required IconData icon,
    VoidCallback? onTap, // Permitimos pasar una función para el tap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white, 
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}