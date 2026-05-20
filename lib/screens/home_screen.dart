import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'confirmar_unirse_screen.dart';
import '../theme/colors.dart';
import 'package:intl/intl.dart';
import 'notifications_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filtroActivo = 'Todos';

  List<Map<String, dynamic>> _partidosRecientes = [];

  final List<Map<String, dynamic>> categorias = [
    {'title': 'Todos', 'emoji': '🌍'},
    {'title': 'Fútbol', 'emoji': '⚽'},
    {'title': 'Baloncesto', 'emoji': '🏀'},
    {'title': 'Tenis', 'emoji': '🎾'},
    {'title': 'Pádel', 'emoji': '🏓'},
    {'title': 'Ultimate', 'emoji': '🥏'},
    {'title': 'Vóley', 'emoji': '🏐'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarHistorialReciente(); // Cargar el historial al iniciar la pantalla
  }

  // 🔹 NUEVO: Método para cargar el historial local
  Future<void> _cargarHistorialReciente() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historialJson = prefs.getString('partidos_recientes');

    if (historialJson != null) {
      setState(() {
        _partidosRecientes =
            List<Map<String, dynamic>>.from(json.decode(historialJson));
      });
    }
  }

  // 🔹 NUEVO: Método para guardar en el historial cuando visitan un partido
  Future<void> _guardarEnHistorial(
      String matchId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Evitamos duplicados quitando el partido si ya existía en la lista
    _partidosRecientes.removeWhere((partido) => partido['id'] == matchId);

    // Guardamos solo los datos básicos necesarios para la tarjeta de acceso rápido.
    // (Evitamos guardar Timestamp porque no se lleva bien con JSON)
    final datosSeguros = {
      'id': matchId,
      'title': data['title']?.toString() ?? 'Partido',
      'sport': data['sport']?.toString() ?? 'Deporte',
    };

    // Lo insertamos en la primera posición (el más reciente)
    _partidosRecientes.insert(0, datosSeguros);

    // Mantenemos solo los últimos 5 partidos visitados
    if (_partidosRecientes.length > 5) {
      _partidosRecientes.removeLast();
    }

    await prefs.setString(
        'partidos_recientes', json.encode(_partidosRecientes));
    setState(() {}); // Actualizamos la UI
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // 🔹 NUEVO: Mostramos la sección de recientes solo si hay datos
            if (_partidosRecientes.isNotEmpty)
              _buildSeccionRecientes(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                padding: pagePadding,
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
      padding: EdgeInsets.fromLTRB(padding.r, (screenHeight * 0.028).r,
          padding.r, (screenHeight * 0.012).r),
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
                    fontSize: titleSize.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: (screenHeight * 0.005).h),
                Text(
                  'Encuentra tu próximo partido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: subtitleSize.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: (screenWidth * 0.03).w),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            child: Container(
              width: iconBox.w,
              height: iconBox.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular((screenWidth * 0.045).r),
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
                size: (iconBox * 0.48).r,
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
      height: height.h,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: (screenWidth * 0.035).r),
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
              margin: EdgeInsets.symmetric(horizontal: (screenWidth * 0.018).r),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular((screenWidth * 0.06).r),
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
                        fontSize: (screenWidth * 0.07).clamp(22.0, 30.0).sp),
                  ),
                  SizedBox(height: (screenHeight * 0.009).h),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: (screenWidth * 0.01).r),
                    child: Text(
                      cat['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: (screenWidth * 0.032).clamp(11.0, 14.0).sp,
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

  // 🔹 NUEVO: UI para los accesos rápidos
  Widget _buildSeccionRecientes({
    required double screenWidth,
    required double screenHeight,
    required double padding,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
              left: padding.r,
              right: padding.r,
              top: (screenHeight * 0.02).r,
              bottom: (screenHeight * 0.01).r),
          child: Text(
            'Vistos recientemente',
            style: TextStyle(
              fontSize: (screenWidth * 0.042).clamp(14.0, 18.0).sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: (screenHeight * 0.08).clamp(60.0, 75.0).h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
                horizontal: padding - (screenWidth * 0.018).r),
            scrollDirection: Axis.horizontal,
            itemCount: _partidosRecientes.length,
            itemBuilder: (context, index) {
              final partido = _partidosRecientes[index];
              final sportIcon = _getSportIcon(partido['sport']);

              return GestureDetector(
                onTap: () async {
                  // Como solo tenemos datos básicos guardados, descargamos el partido completo de Firestore
                  // antes de entrar a la pantalla de detalles.
                  final doc = await FirebaseFirestore.instance
                      .collection('matches')
                      .doc(partido['id'])
                      .get();
                  if (!context.mounted) return;
                  if (doc.exists) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConfirmarUnirseScreen(
                          matchId: partido['id'],
                          matchData: doc.data() as Map<String, dynamic>,
                        ),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Este partido ya no está disponible')),
                    );
                  }
                },
                child: Container(
                  width: (screenWidth * 0.45).clamp(150.0, 200.0).w,
                  margin: EdgeInsets.symmetric(
                      horizontal: (screenWidth * 0.018).r,
                      vertical: (screenHeight * 0.005).r),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(sportIcon,
                            color: AppColors.primary, size: 18.r),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              partido['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                            Text(
                              partido['sport'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                // <--- ¡Solucionado!
                                color: AppColors.textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

        final ahora = DateTime.now();
        final partidosVigentes = snapshot.data!.docs.where((doc) {
          final rawData = doc.data();
          if (rawData is! Map<String, dynamic>) return false;

          if (rawData['date'] is Timestamp) {
            final fechaPartido = (rawData['date'] as Timestamp).toDate();
            return fechaPartido.isAfter(ahora);
          }
          return true;
        }).toList();

        if (partidosVigentes.isEmpty) {
          return const Center(
              child: Text('No hay próximos partidos para este deporte'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(padding.r),
          itemCount: partidosVigentes.length,
          itemBuilder: (context, index) {
            final doc = partidosVigentes[index];
            final rawData = doc.data() as Map<String, dynamic>;

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

  IconData _getSportIcon(String sport) {
    final lowerSport = sport.toLowerCase();
    if (lowerSport.contains('futbol') || lowerSport.contains('fútbol')) {
      return Icons.sports_soccer;
    } else if (lowerSport.contains('baloncesto') || lowerSport.contains('basket')) {
      return Icons.sports_basketball;
    } else if (lowerSport.contains('tenis') || lowerSport.contains('padel') || lowerSport.contains('pádel')) {
      return Icons.sports_tennis;
    } else if (lowerSport.contains('ultimate')) {
      return Icons.animation;
    } else if (lowerSport.contains('vóley') || lowerSport.contains('voley')) {
      return Icons.sports_volleyball;
    }
    return Icons.sports;
  }

  Widget _buildMatchCard(
    Map<String, dynamic> data,
    String docId, {
    required double screenWidth,
    required double screenHeight,
  }) {
    final title = data['title']?.toString() ?? 'Partido';
    final sport = data['sport']?.toString() ?? 'Deporte';
    final location = data['location']?.toString() ?? 'Ubicación';
    final joined = (data['joinedSlots'] as num?)?.toInt() ?? 0;
    final total = ((data['totalSlots'] as num?)?.toInt() ?? 10).clamp(1, 9999);
    final progress = (joined / total).clamp(0.0, 1.0);
    final cardPadding = screenWidth * 0.055;
    final iconSize = (screenWidth * 0.145).clamp(50.0, 64.0);

    final sportIcon = _getSportIcon(sport);

    String dateStr = 'Fecha pendiente';
    if (data['date'] is Timestamp) {
      final dateTime = (data['date'] as Timestamp).toDate();
      dateStr = DateFormat('dd MMM • hh:mm a', 'es').format(dateTime);
    }

    return GestureDetector(
      onTap: () {
        // 🔹 NUEVO: Guardar en el historial local antes de navegar
        _guardarEnHistorial(docId, data);

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
        margin: EdgeInsets.only(bottom: (screenHeight * 0.026).r),
        padding: EdgeInsets.all(cardPadding.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular((screenWidth * 0.07).r),
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
                    borderRadius:
                        BorderRadius.circular((screenWidth * 0.045).r),
                  ),
                  child: Icon(
                    sportIcon,
                    color: AppColors.primary,
                    size: (iconSize * 0.52).r,
                  ),
                ),
                SizedBox(width: (screenWidth * 0.04).w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (screenWidth * 0.05).clamp(17.0, 21.0).sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: (screenHeight * 0.005).h),
                      Text(
                        sport,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: (screenWidth * 0.035).clamp(12.0, 15.0).sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: (screenHeight * 0.024).h),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: (screenWidth * 0.04).r, color: AppColors.primary),
                SizedBox(width: (screenWidth * 0.02).w),
                Expanded(
                  child: Text(
                    dateStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: (screenWidth * 0.035).clamp(12.0, 15.0).sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: (screenHeight * 0.012).h),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: (screenWidth * 0.045).r, color: AppColors.primary),
                SizedBox(width: (screenWidth * 0.02).w),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: (screenWidth * 0.035).clamp(12.0, 15.0).sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: (screenHeight * 0.024).h),
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
                          fontSize: (screenWidth * 0.032).clamp(11.0, 14.0).sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.032).clamp(11.0, 14.0).sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: (screenHeight * 0.01).h),
                ClipRRect(
                  borderRadius: BorderRadius.circular((screenWidth * 0.025).r),
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
