import 'package:flutter/material.dart';
// Asegúrate de que estas rutas coincidan con la estructura de tus carpetas
import 'home_screen.dart';
import 'sign_in_screen.dart';
// Importamos el servicio que creamos en el paso anterior
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 🔹 CONTROLADORES PARA LEER LOS CAMPOS DE TEXTO
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // 🔹 ESTADO PARA MOSTRAR SPINNER DE CARGA
  bool _isLoading = false;

  // 🔹 FUNCIÓN PARA INICIAR SESIÓN
  void _login() async {
    // Validar que los campos no estén vacíos
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Llamamos a nuestro backend (Firebase)
    final user = await AuthService().loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user != null) {
      // Si el usuario existe y la clave es correcta, vamos al Home
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Si hay error (datos incorrectos)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos incorrectos. Verifica tu correo y contraseña.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Limpiamos la memoria al cerrar la pantalla
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 390,
            height: double.infinity, // Ajustado para evitar desbordamientos
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView( // Añadido para que el teclado no tape los botones
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
                    controller: _emailController, // Conectamos el controlador
                  ),

                  const SizedBox(height: 16),

                  // 🔹 PASSWORD INPUT
                  _inputField(
                    hint: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscure: true,
                    controller: _passwordController, // Conectamos el controlador
                  ),

                  const SizedBox(height: 16),

                  // 🔹 LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login, // Lógica de carga y backend
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
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
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
                      onPressed: () {
                        // Navegación hacia la pantalla de registro
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
                      Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'O continúa con',
                          style: TextStyle(fontSize: 14, color: Color(0xFF6A7282)),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 🔹 SOCIAL BUTTONS
                  Row(
                    children: [
                      Expanded(child: _socialButton(text: 'Google', icon: Icons.g_mobiledata)),
                      const SizedBox(width: 16),
                      Expanded(child: _socialButton(text: 'Apple', icon: Icons.apple)),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 INPUT COMPONENT MODIFICADO
  Widget _inputField({
    required String hint,
    required IconData icon,
    bool obscure = false,
    required TextEditingController controller, // Ahora requiere el controlador
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller, // Asignamos el controlador al input real
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54, fontSize: 16),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  // 🔹 SOCIAL BUTTON
  Widget _socialButton({
    required String text,
    required IconData icon,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}