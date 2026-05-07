import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔹 Importamos Firestore

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),

      // 🔻 BOTTOM NAV
      bottomNavigationBar: _bottomNav(),

      body: SafeArea(
        child: Stack(
          children: [
            // 🔹 SCROLL CONTENT
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _categories(),
                  const SizedBox(height: 24),
                  const Text(
                    'Partidos Disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 LISTA DESDE FIREBASE CON STREAMBUILDER
                  StreamBuilder<QuerySnapshot>(
                    // Escuchamos la colección 'matches'
                    stream: FirebaseFirestore.instance.collection('matches').snapshots(),
                    builder: (context, snapshot) {
                      // 1. Mientras carga
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                          ),
                        );
                      }

                      // 2. Si hay un error
                      if (snapshot.hasError) {
                        return const Text('Error al cargar los partidos.');
                      }

                      // 3. Si no hay datos o la colección está vacía
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'No hay partidos disponibles por ahora.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      // 4. Mapeamos los documentos a nuestras Cards
                      final matches = snapshot.data!.docs;
                      
                      return Column(
                        children: matches.map((doc) {
                          // Convertimos el documento de Firebase a un Map
                          final data = doc.data() as Map<String, dynamic>;
                          return _matchCard(data, doc.id); // Pasamos el ID por si luego queremos unirnos
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  _eventBanner(),
                ],
              ),
            ),

            // 🔹 FLOAT BUTTON
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: () {
                    // Aquí luego pondremos la lógica para CREAR un partido
                  },
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 HEADER
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game On',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            Text(
              'Encuentra tu partido',
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontSize: 13,
              ),
            ),
          ],
        ),
        Icon(Icons.notifications_none),
      ],
    );
  }

  // 🔹 CATEGORÍAS (horizontal)
  Widget _categories() {
    final items = [
      {'emoji': '🥏', 'title': 'Ultimate', 'color': Colors.teal}, // Agregamos Ultimate como pediste
      {'emoji': '🎾', 'title': 'Pádel', 'color': Colors.blue},
      {'emoji': '⚽', 'title': 'Fútbol', 'color': Colors.green},
    ];

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final item = items[i];

          return Container(
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: item['color'] as Color,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['emoji'] as String,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 CARD PARTIDO ACTUALIZADA PARA RECIBIR TIPOS SEGUROS
  Widget _matchCard(Map<String, dynamic> data, String matchId) {
    // Usamos ?? para dar valores por defecto por si algún campo falta en Firebase
    final String title = data['title'] ?? 'Partido sin nombre';
    final String location = data['location'] ?? 'Ubicación pendiente';
    final String date = data['date'] ?? 'Fecha por definir';
    final String time = data['time'] ?? '--:--';
    final String slots = data['slots'] ?? '0/0';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Colors.black12,
          )
        ],
      ),
      child: Row(
        children: [
          // 🔹 IMAGE
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[300],
            ),
            child: const Center(
              child: Icon(Icons.sports, color: Colors.grey), // Icono por defecto temporal
            ),
          ),

          const SizedBox(width: 12),

          // 🔹 INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(color: Colors.black87),
                        overflow: TextOverflow.ellipsis, // Por si el texto es muy largo
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(date, style: const TextStyle(color: Colors.black87)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(time, style: const TextStyle(color: Colors.black87)),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  '$slots Cupos Libres',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 BUTTON
          ElevatedButton(
            onPressed: () {
              // Aquí haremos la lógica para unirse usando el matchId
              print('Unirse al partido: $matchId');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text(
              'Unirme',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  // 🔹 EVENTOS BANNER
  Widget _eventBanner() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.blue,
      ),
      child: const Center(
        child: Text(
          'Eventos y Torneos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🔹 NAVBAR
  Widget _bottomNav() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Icon(Icons.home, color: Color(0xFF2E7D32), size: 28),
          Icon(Icons.calendar_today, color: Colors.grey, size: 28),
          SizedBox(width: 40), // espacio para botón central
          Icon(Icons.emoji_events_outlined, color: Colors.grey, size: 28),
          Icon(Icons.person_outline, color: Colors.grey, size: 28),
        ],
      ),
    );
  }
}