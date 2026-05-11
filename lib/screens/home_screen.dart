import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'confirmar_unirse_screen.dart';
import '../theme/colors.dart';
import 'package:intl/intl.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filtroActivo = 'Todos';

  final List<Map<String, dynamic>> categorias = [
    {'title': 'Todos', 'emoji': '🌍'},
    {'title': 'Futbol', 'emoji': '⚽'},
    {'title': 'Baloncesto', 'emoji': '🏀'},
    {'title': 'Padel', 'emoji': '🎾'},
    {'title': 'Tenis', 'emoji': '🎾'},
    {'title': 'Ultimate', 'emoji': '🥏'},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final pagePadding = screenWidth * 0.055;
    final titleSize = (screenWidth * 0.085).clamp(26.0, 34.0);
    final subtitleSize = (screenWidth * 0.038).clamp(13.0, 16.0);
    final filterHeight = (screenHeight * 0.115).clamp(82.0, 104.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              padding: pagePadding,
              titleSize: titleSize,
              subtitleSize: subtitleSize,
            ),
            _buildFiltrosHorizontal(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              height: filterHeight,
            ),
            Expanded(
              child: _buildListaStream(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                padding: pagePadding,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required double screenWidth,
    required double screenHeight,
    required double padding,
    required double titleSize,
    required double subtitleSize,
  }) {
    final iconBox = (screenWidth * 0.135).clamp(48.0, 58.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          padding, screenHeight * 0.028, padding, screenHeight * 0.012),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GameOn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  'Encuentra tu proximo partido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            child: Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.045),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: screenWidth * 0.025,
                    offset: Offset(0, screenHeight * 0.005),
                  )
                ],
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
                size: iconBox * 0.48,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosHorizontal({
    required double screenWidth,
    required double screenHeight,
    required double height,
  }) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.035),
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        itemBuilder: (context, i) {
          final cat = categorias[i];
          final selected = _filtroActivo == cat['title'];
          final cardWidth = (screenWidth * 0.205).clamp(74.0, 92.0);

          return GestureDetector(
            onTap: () {
              setState(() {
                _filtroActivo = cat['title'];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: cardWidth,
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.018),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.06),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: screenWidth * 0.025,
                    offset: Offset(0, screenHeight * 0.005),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cat['emoji'],
                    style: TextStyle(
                        fontSize: (screenWidth * 0.07).clamp(22.0, 30.0)),
                  ),
                  SizedBox(height: screenHeight * 0.009),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                    child: Text(
                      cat['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
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

  Widget _buildListaStream({
    required double screenWidth,
    required double screenHeight,
    required double padding,
  }) {
    Query query = FirebaseFirestore.instance.collection('matches');

    if (_filtroActivo != 'Todos') {
      query = query.where('sport', isEqualTo: _filtroActivo);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('No pudimos cargar los partidos.'));
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay partidos para este deporte'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(padding),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final rawData = doc.data();
            if (rawData is! Map<String, dynamic>) {
              return const SizedBox.shrink();
            }

            return _buildMatchCard(
              rawData,
              doc.id,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
            );
          },
        );
      },
    );
  }

  Widget _buildMatchCard(
    Map<String, dynamic> data,
    String docId, {
    required double screenWidth,
    required double screenHeight,
  }) {
    final title = data['title']?.toString() ?? 'Partido';
    final sport = data['sport']?.toString() ?? 'Deporte';
    final location = data['location']?.toString() ?? 'Ubicacion';
    final joined = (data['joinedSlots'] as num?)?.toInt() ?? 0;
    final total = ((data['totalSlots'] as num?)?.toInt() ?? 10).clamp(1, 9999);
    final progress = (joined / total).clamp(0.0, 1.0);
    final cardPadding = screenWidth * 0.055;
    final iconSize = (screenWidth * 0.145).clamp(50.0, 64.0);

    String dateStr = 'Fecha pendiente';
    if (data['date'] is Timestamp) {
      final dateTime = (data['date'] as Timestamp).toDate();
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
        margin: EdgeInsets.only(bottom: screenHeight * 0.026),
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.07),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: screenWidth * 0.035,
              offset: Offset(0, screenHeight * 0.01),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(screenWidth * 0.045),
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    color: AppColors.primary,
                    size: iconSize * 0.52,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (screenWidth * 0.05).clamp(17.0, 21.0),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        sport,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: (screenWidth * 0.035).clamp(12.0, 15.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.024),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: screenWidth * 0.04, color: AppColors.primary),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    dateStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: (screenWidth * 0.035).clamp(12.0, 15.0),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.012),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: screenWidth * 0.045, color: AppColors.primary),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: (screenWidth * 0.035).clamp(12.0, 15.0),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.024),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '$joined / $total jugadores',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: screenHeight * 0.01,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.red : AppColors.primary,
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
