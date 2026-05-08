import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'eventos_screen.dart';
import 'agenda_screen.dart';
import 'perfil_screen.dart';
import 'crear_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Lista de pantallas principales
  final List<Widget> _screens = [
    const HomeScreen(),
    const EventsScreen(), 
    const AgendaScreen(),
    const PerfilScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔹 SOLUCIÓN CRÍTICA AL CRASH: Cambiamos el IndexedStack por la pantalla directa.
      // Ahora solo carga la pantalla que necesitas, liberando el 75% del trabajo de memoria.
      body: _screens[_selectedIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearScreen()),
          );
        },
        backgroundColor: const Color(0xFF2E7D32),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lado Izquierdo: Home y Eventos
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _navItem(Icons.home, "Inicio", 0),
                  _navItem(Icons.explore, "Eventos", 1),
                ],
              ),
              // Lado Derecho: Agenda y Perfil
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _navItem(Icons.calendar_today, "Agenda", 2),
                  _navItem(Icons.person, "Perfil", 3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para los íconos de la barra
  Widget _navItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    return MaterialButton(
      minWidth: 40,
      onPressed: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}