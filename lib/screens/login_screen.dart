import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 390,
            height: 844,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 120),

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
                ),

                const SizedBox(height: 16),

                // 🔹 PASSWORD INPUT
                _inputField(
                  hint: 'Contraseña',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),

                const SizedBox(height: 16),

                // 🔹 LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
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
                    onPressed: () {},
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
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _socialButton(
                        text: 'Apple',
                        icon: Icons.apple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 INPUT COMPONENT
  Widget _inputField({
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}