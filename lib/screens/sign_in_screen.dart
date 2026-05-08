import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔹 Agregado para guardar el perfil
import 'package:firebase_auth/firebase_auth.dart';     // 🔹 Agregado para el manejo de errores
import 'main_navigation_screen.dart';
import '../services/auth_service.dart'; // Importamos el backend

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // 🔹 VARIABLES DE ESTADO
  bool obscure1 = true;
  bool obscure2 = true;
  bool _isLoading = false;

  String? selectedSport;
  String? selectedLevel;

  final sports = ['Fútbol', 'Basket', 'Tenis', 'Ultimate', 'Otro'];
  final levels = ['Principiante', 'Intermedio', 'Avanzado'];

  // 🔹 CONTROLADORES DE TEXTO
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // 🔹 LÓGICA DE REGISTRO
  void _register() async {
    // 1. Validar que no haya campos vacíos
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty ||
        selectedSport == null || 
        selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena todos los campos y selecciones.')),
      );
      return;
    }

    // 2. Validar que las contraseñas coincidan
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 3. Iniciar estado de carga
    setState(() => _isLoading = true);

    try {
      // 4. Crear usuario en Auth
      final user = await AuthService().registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // 5. Guardar Perfil en Firestore [P1]
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'sport': selectedSport,
          'level': selectedLevel,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Capturamos el error real gracias a la mejora en AuthService
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error al registrar usuario'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // Liberar memoria al cerrar la pantalla
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 HEADER
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 BODY
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 🔹 FOTO PERFIL
                    Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  '👤',
                                  style: TextStyle(fontSize: 40),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Añadir foto (Opcional)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6A7282),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 🔹 FORMULARIO
                    _label('Nombre Completo'),
                    _input('Nombre', _nameController),

                    _label('Correo Electrónico'),
                    _input('tu@correo.com', _emailController),

                    _label('Contraseña'),
                    _passwordInput(
                      obscure1,
                      () => setState(() => obscure1 = !obscure1),
                      _passwordController,
                    ),

                    _label('Confirmar Contraseña'),
                    _passwordInput(
                      obscure2,
                      () => setState(() => obscure2 = !obscure2),
                      _confirmPasswordController,
                    ),

                    _label('Deporte Preferido'),
                    _dropdown(sports, selectedSport, (v) {
                      setState(() => selectedSport = v);
                    }),

                    _label('Nivel de Juego'),
                    _dropdown(levels, selectedLevel, (v) {
                      setState(() => selectedLevel = v);
                    }),

                    const SizedBox(height: 24),

                    // 🔹 BOTÓN COMPLETAR REGISTRO
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Completar Registro',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 LOGIN LINK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿Ya tienes cuenta? ',
                          style: TextStyle(
                            color: Color(0xFF4A5565),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 LABEL
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF364153),
          ),
        ),
      ),
    );
  }

  // 🔹 INPUT MODIFICADO PARA RECIBIR CONTROLADOR
  Widget _input(String hint, TextEditingController controller) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  // 🔹 PASSWORD INPUT MODIFICADO PARA RECIBIR CONTROLADOR
  Widget _passwordInput(bool obscure, VoidCallback toggle, TextEditingController controller) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: '••••••••',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }

  // 🔹 DROPDOWN
  Widget _dropdown(
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text('Seleccionar'),
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}