import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 24),
              const _FeaturedEventCard(),
              const SizedBox(height: 24),
              _sectionTitle('Próximos Eventos'),
              const SizedBox(height: 12),
              const _EventCard(
                title: 'Copa Voley Playa',
                prize: '\$2.500.000 COP',
                date: '10 - 11 Mayo',
                place: 'Barena',
                players: '12/24',
                icon: Icons.sports_volleyball,
              ),
              const SizedBox(height: 12),
              const _EventCard(
                title: 'Torneo Flota Chancle',
                prize: '\$1.000.000 COP',
                date: 'Sábado 18 - Domingo 19 Mayo',
                place: 'Cancha UAO',
                players: '8/10',
                icon: Icons.sports_soccer,
              ),
              const SizedBox(height: 12),
              const _EventCard(
                title: 'Open Tenis Cali',
                prize: '\$3.000.000 COP',
                date: 'Lunes 20 - Jueves 23 Mayo',
                place: 'Club Campestre',
                players: '20/32',
                icon: Icons.sports_tennis,
              ),
              const SizedBox(height: 24),
              _sectionTitle('En Curso'),
              const SizedBox(height: 12),
              const _EventCard(
                title: 'Liga Fútbol 7',
                prize: '\$8.000.000 COP',
                date: 'En curso - Finaliza 30 Mayo',
                place: 'La Chilena',
                players: '15/16',
                icon: Icons.sports_soccer,
                inProgress: true,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eventos',
              style: TextStyle(
                color: Color(0xFF155DFC),
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Torneos y competencias oficiales',
              style: TextStyle(
                color: Color(0xFF4A5565),
                fontSize: 14,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, color: Color(0xFF111827)),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _FeaturedEventCard extends StatelessWidget {
  const _FeaturedEventCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(radius: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 224,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF155DFC),
                  Color(0xFF2E7D32),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                const Positioned(
                  left: 16,
                  bottom: 20,
                  child: Text(
                    'Cali Vive el Pádel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6900),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'DESTACADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFF7ED),
                        Color(0xFFFEFCE8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFFFF6900),
                        child: Icon(Icons.emoji_events, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premio Total',
                            style: TextStyle(
                              color: Color(0xFF4A5565),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '\$5.000.000 COP',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _InfoRow(
                  icon: Icons.calendar_today,
                  text: 'Sábado 14 - Domingo 15 Marzo',
                ),
                const SizedBox(height: 12),
                const _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: 'Padeling by Cabal',
                ),
                const SizedBox(height: 12),
                const _InfoRow(
                  icon: Icons.people_outline,
                  text: '42 / 64 inscritos',
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 8,
                    backgroundColor: Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '65%',
                    style: TextStyle(
                      color: Color(0xFF6A7282),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                    ),
                    child: const Text(
                      'Inscribirse Ahora',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
}

class _EventCard extends StatelessWidget {
  final String title;
  final String prize;
  final String date;
  final String place;
  final String players;
  final IconData icon;
  final bool inProgress;

  const _EventCard({
    required this.title,
    required this.prize,
    required this.date,
    required this.place,
    required this.players,
    required this.icon,
    this.inProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 44,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              if (inProgress)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6900),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EN CURSO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _SmallInfoRow(
                  icon: Icons.emoji_events_outlined,
                  text: prize,
                  color: const Color(0xFFF54900),
                  bold: true,
                ),
                const SizedBox(height: 4),
                _SmallInfoRow(
                  icon: Icons.calendar_today,
                  text: date,
                ),
                const SizedBox(height: 4),
                _SmallInfoRow(
                  icon: Icons.location_on_outlined,
                  text: place,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 14,
                      color: Color(0xFF4A5565),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      players,
                      style: const TextStyle(
                        color: Color(0xFF4A5565),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Ver más',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4A5565)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4A5565),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool bold;

  const _SmallInfoRow({
    required this.icon,
    required this.text,
    this.color = const Color(0xFF4A5565),
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _cardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(20),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}