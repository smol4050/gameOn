import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'confirmar_unirse_screen.dart'; // 🔹 Importamos la pantalla

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 🔹 FUNCIÓN SEEDER PARA POBLAR FIREBASE (Con 6 partidos más)
  Future<void> _seedDatabase(BuildContext context) async {
    final mockMatches = [
      {'title': 'Basket 3x3 Callejero', 'location': 'Parque del Perro', 'date': '29 abr', 'time': '17:00', 'slots': '6/12'},
      {'title': 'Tenis Dobles (Nivel B)', 'location': 'Club Campestre', 'date': '30 abr', 'time': '08:00', 'slots': '2/4'},
      {'title': 'Voley Arena Mixto', 'location': 'Canchas Panamericanas', 'date': '01 may', 'time': '16:00', 'slots': '10/12'},
      {'title': 'Fútbol 5 Femenino', 'location': 'Gol 5, Sur', 'date': '02 may', 'time': '19:00', 'slots': '5/10'},
      {'title': 'Ultimate Mixto Open', 'location': 'Cancha Blanca, Norte', 'date': '03 may', 'time': '15:00', 'slots': '12/20'},
      {'title': 'Pádel Nivel Pro', 'location': 'Padel House', 'date': '04 may', 'time': '20:00', 'slots': '1/4'},
    ];

    try {
      final collection = FirebaseFirestore.instance.collection('matches');
      for (var match in mockMatches) {
        await collection.add(match);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ¡Base de datos poblada!', style: TextStyle(color: Colors.white))));
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      bottomNavigationBar: _bottomNav(),
      body: SafeArea(
        child: Stack(
          children: [
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF101828)),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 LISTA DESDE FIREBASE
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('matches').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Color(0xFF2E7D32))));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No hay partidos disponibles.', style: TextStyle(color: Colors.grey))));
                      }

                      final matches = snapshot.data!.docs;
                      return Column(
                        children: matches.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _matchCard(context, data, doc.id);
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  _eventBanner(),
                ],
              ),
            ),
            
            // 🔹 FLOAT BUTTON PARA SEEDER (Temporal)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: () => _seedDatabase(context),
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

  // 🔹 CARD PARTIDO
  Widget _matchCard(BuildContext context, Map<String, dynamic> data, String matchId) {
    final title = data['title'] ?? 'Partido';
    final location = data['location'] ?? 'Ubicación';
    final date = data['date'] ?? 'Fecha';
    final time = data['time'] ?? '--:--';
    final slots = data['slots'] ?? '0/0';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [BoxShadow(blurRadius: 10, offset: Offset(0, 4), color: Colors.black12)],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[300]),
            child: const Icon(Icons.sports_basketball, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(location, style: const TextStyle(color: Colors.black87), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$date • $time', style: const TextStyle(color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('$slots Cupos Libres', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // 🔹 NAVEGAMOS A LA CONFIRMACIÓN
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfirmarUnirseScreen(matchId: matchId, matchData: data),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Ver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // HEADER, CATEGORIES, BANNER, NAVBAR... (Iguales que antes)
  Widget _header() { return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Game On', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))), Text('Encuentra tu partido', style: TextStyle(color: Color(0xFF1976D2), fontSize: 13))]), Icon(Icons.notifications_none)]); }
  Widget _categories() { final items = [{'emoji': '🥏', 'title': 'Ultimate', 'color': Colors.teal}, {'emoji': '🎾', 'title': 'Pádel', 'color': Colors.blue}, {'emoji': '⚽', 'title': 'Fútbol', 'color': Colors.green}]; return SizedBox(height: 160, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, i) { final item = items[i]; return Container(width: 140, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: item['color'] as Color), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(item['emoji'] as String, style: const TextStyle(fontSize: 36)), const SizedBox(height: 8), Text(item['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))); })); }
  Widget _eventBanner() { return Container(height: 140, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.blue), child: const Center(child: Text('Eventos y Torneos', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))); }
  Widget _bottomNav() { return Container(height: 80, padding: const EdgeInsets.symmetric(horizontal: 24), decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Icon(Icons.home, color: Color(0xFF2E7D32), size: 28), Icon(Icons.calendar_today, color: Colors.grey, size: 28), SizedBox(width: 40), Icon(Icons.emoji_events_outlined, color: Colors.grey, size: 28), Icon(Icons.person_outline, color: Colors.grey, size: 28)])); }
}