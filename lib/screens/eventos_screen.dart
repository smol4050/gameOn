import 'package:flutter/material.dart';
import 'confirmar_unirse_screen.dart'; // 🔹 Importante para que funcione la navegación

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 HEADER
              Container(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF3F4F6)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eventos',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF155DFC),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Torneos y competencias oficiales',
                          style:
                              TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 28,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🔥 EVENTO DESTACADO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child:
                    _featuredEvent(context), // 🔹 Pasamos context para navegar
              ),

              const SizedBox(height: 28),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Próximos Eventos',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827)),
                ),
              ),

              const SizedBox(height: 18),

              // 🔹 LISTA DE PRÓXIMOS EVENTOS
              ...upcomingEvents
                  .map((event) => _eventCard(context, event))
                  .toList(),

              const SizedBox(height: 30),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'En Curso',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827)),
                ),
              ),

              const SizedBox(height: 18),

              _eventCard(
                context,
                ongoingEvent,
                ongoing: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 FEATURED EVENT
  Widget _featuredEvent(BuildContext context) {
    // Definimos la data del evento destacado para que coincida con lo que espera la otra pantalla
    final featuredData = {
      'title': 'Cali Vive el Pádel',
      'sport': 'Pádel',
      'price': '\$5.000.000 COP',
      'date': '14 - 15 Marzo',
      'location': 'Padeling by Cabal',
      'joinedSlots': 42,
      'totalSlots': 64,
      'image':
          'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?q=80&w=1200&auto=format&fit=crop',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(blurRadius: 18, offset: Offset(0, 6), color: Colors.black12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: Image.network(
                  featuredData['image'].toString(),
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: 240,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF6900),
                      borderRadius: BorderRadius.circular(50)),
                  child: const Text(
                    'DESTACADO',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 22,
                child: Text(
                  featuredData['title'].toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _infoRow(Icons.calendar_today_outlined,
                    featuredData['date'].toString()),
                const SizedBox(height: 14),
                _infoRow(Icons.location_on_outlined,
                    featuredData['location'].toString()),
                const SizedBox(height: 28),

                // 🔹 BUTTON DESTACADO
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF155DFC), Color(0xFF2E7D32)]),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // 🔹 NAVEGACIÓN AL EVENTO DESTACADO
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ConfirmarUnirseScreen(
                                    matchId: 'feat_001',
                                    matchData: featuredData)));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent),
                      child: const Text(
                        'Inscribirse Ahora',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white), // 🔹 Letra Blanca
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 EVENT CARD
  Widget _eventCard(BuildContext context, Map<String, dynamic> event,
      {bool ongoing = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                blurRadius: 10, offset: Offset(0, 3), color: Colors.black12)
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(event['image'],
                      width: 100, height: 100, fit: BoxFit.cover),
                ),
                if (ongoing)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFF6900),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('EN CURSO',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 8),
                  _miniInfo(Icons.attach_money, event['price'], orange: true),
                  const SizedBox(height: 4),
                  _miniInfo(Icons.location_on_outlined, event['location']),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // 🔹 NAVEGACIÓN DESDE LA CARD
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ConfirmarUnirseScreen(
                                    matchId: 'event_${event['title']}',
                                    matchData: event)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Ver más',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white), // 🔹 Letra Blanca
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF155DFC), size: 20),
        const SizedBox(width: 12),
        Text(text,
            style: const TextStyle(color: Color(0xFF4A5565), fontSize: 15)),
      ],
    );
  }

  Widget _miniInfo(IconData icon, String text, {bool orange = false}) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color: orange ? const Color(0xFFF54900) : const Color(0xFF6A7282)),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color:
                    orange ? const Color(0xFFF54900) : const Color(0xFF4A5565),
                fontSize: 12)),
      ],
    );
  }
}

// 🔥 MOCK DATA (Agregamos cupos para que la barra de progreso funcione)
final upcomingEvents = [
  {
    'title': 'Copa Voley Playa',
    'sport': 'Voley',
    'price': '\$2.500.000 COP',
    'date': '10 - 11 Mayo',
    'location': 'Barena',
    'joinedSlots': 12,
    'totalSlots': 24,
    'image':
        'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?q=80&w=1200&auto=format&fit=crop',
  },
  {
    'title': 'Torneo Flota Chancle',
    'sport': 'Fútbol',
    'price': '\$1.000.000 COP',
    'date': '18 - 19 Mayo',
    'location': 'Cancha UAO',
    'joinedSlots': 8,
    'totalSlots': 10,
    'image':
        'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?q=80&w=1200&auto=format&fit=crop',
  },
  {
    'title': 'Open Tenis Cali',
    'sport': 'Tenis',
    'price': '\$3.000.000 COP',
    'date': '20 - 23 Mayo',
    'location': 'Club Campestre',
    'joinedSlots': 20,
    'totalSlots': 32,
    'image':
        'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?q=80&w=1200&auto=format&fit=crop',
  },
];

final ongoingEvent = {
  'title': 'Liga Fútbol 7',
  'sport': 'Fútbol',
  'price': '\$8.000.000 COP',
  'date': 'Finaliza 30 Mayo',
  'location': 'La Chilena',
  'joinedSlots': 15,
  'totalSlots': 16,
  'image':
      'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?q=80&w=1200&auto=format&fit=crop',
};
