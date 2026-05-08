import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'confirmar_unirse_screen.dart';
import '../theme/colors.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filtroActivo = 'Todos';

  final List<Map<String, dynamic>> categorias = [
    {'title': 'Todos', 'emoji': '🌍'},
    {'title': 'Fútbol', 'emoji': '⚽'},
    {'title': 'Baloncesto', 'emoji': '🏀'},
    {'title': 'Pádel', 'emoji': '🎾'},
    {'title': 'Tenis', 'emoji': '🎾'},
    {'title': 'Ultimate', 'emoji': '🥏'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFiltrosHorizontal(),
            Expanded(
              child: _buildListaStream(),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER MODERNO
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GameOn',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Encuentra tu próximo partido',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // FILTROS HORIZONTALES
  Widget _buildFiltrosHorizontal() {
    return SizedBox(
      height: 95,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        itemBuilder: (context, i) {
          final cat = categorias[i];
          final selected = _filtroActivo == cat['title'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _filtroActivo = cat['title'];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 82,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color:
                    selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cat['emoji'],
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary,
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

  // STREAM DE FIREBASE
  Widget _buildListaStream() {
    Query query =
        FirebaseFirestore.instance.collection('matches');

    if (_filtroActivo != 'Todos') {
      query = query.where(
        'sport',
        isEqualTo: _filtroActivo,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No hay partidos para este deporte",
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];

            final data =
                doc.data() as Map<String, dynamic>;

            return _buildMatchCard(data, doc.id);
          },
        );
      },
    );
  }

  // CARD PREMIUM
 Widget _buildMatchCard(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? 'Partido';
    final sport = data['sport'] ?? 'Deporte';
    final location = data['location'] ?? 'Ubicación';
    
    // 🔹 Lógica de Cupos (Slots)
    final int joined = data['joinedSlots'] ?? 0;
    final int total = data['totalSlots'] ?? 10;
    final double progress = (joined / total).clamp(0.0, 1.0);

    // 🔹 Formateo de Fecha Seguro (Timestamp a String)
    String dateStr = 'Fecha pendiente';
    if (data['date'] != null && data['date'] is Timestamp) {
      DateTime dateTime = (data['date'] as Timestamp).toDate();
      dateStr = DateFormat('dd MMMM • hh:mm a', 'es').format(dateTime);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmarUnirseScreen(
              matchId: docId,
              matchData: data,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 22),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.sports_soccer, color: AppColors.primary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(sport, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 🔹 BARRA DE PROGRESO DE CUPOS
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$joined / $total jugadores', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.red : AppColors.primary
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}