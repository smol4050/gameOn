import 'package:flutter/material.dart';

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

                  // 🔹 LISTA
                  ..._matches.map((e) => _matchCard(e)).toList(),

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
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
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
      {'emoji': '🎾', 'title': 'Pádel', 'color': Colors.blue},
      {'emoji': '🏐', 'title': 'Voley', 'color': Colors.orange},
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

  // 🔹 CARD PARTIDO
  Widget _matchCard(Map data) {
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
          ),

          const SizedBox(width: 12),

          // 🔹 INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14),
                    const SizedBox(width: 4),
                    Text(data['location']),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 4),
                    Text(data['date']),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 14),
                    const SizedBox(width: 4),
                    Text(data['time']),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  '${data['slots']} Cupos Libres',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 BUTTON
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Unirme'),
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
          Icon(Icons.home, color: Color(0xFF2E7D32)),
          Icon(Icons.calendar_today),
          SizedBox(width: 40), // espacio para botón central
          Icon(Icons.emoji_events_outlined),
          Icon(Icons.person_outline),
        ],
      ),
    );
  }
}

// 🔹 DATA MOCK
final _matches = [
  {
    'title': 'Reto Pádel 2v2',
    'location': 'Padel Pro, Norte',
    'date': '27 abr',
    'time': '18:00',
    'slots': '4/14',
  },
  {
    'title': 'Entreno Flota',
    'location': 'Cancha UAO, Sur',
    'date': '28 abr',
    'time': '19:00',
    'slots': '6/14',
  },
  {
    'title': 'Futbolito Nocturno',
    'location': 'Gol Cinco, Norte',
    'date': '28 abr',
    'time': '20:00',
    'slots': '8/16',
  },
];