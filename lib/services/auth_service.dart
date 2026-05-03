import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Instancia principal de Firebase Auth
  final FirebaseAuth _auth;

  // El constructor permite inyectar una instancia (vital para hacer pruebas unitarias después)
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // Método para Registrar un usuario
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user; // Devuelve los datos del usuario si fue exitoso
    } catch (e) {
      print('Error en registro: $e');
      return null; // Devuelve null si falló (ej. correo ya existe)
    }
  }

  // Método para Iniciar Sesión
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error en inicio de sesión: $e');
      return null; // Devuelve null si la contraseña es incorrecta
    }
  }

  // Método para Cerrar Sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}