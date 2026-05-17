import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import 'confirmar_unirse_screen.dart';
import 'chat_list_screen.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final pagePadding = screenWidth * 0.055;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              context,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              padding: pagePadding,
            ),
            Expanded(
              child: userId == null
                  ? const Center(
                      child: Text('Inicia sesion para ver tu agenda.'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('agenda')
                          .orderBy('date', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('No pudimos cargar tu agenda.'));
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary));
                        }

                        final allEvents = snapshot.data!.docs;
                        final now = DateTime.now();
                        final todayStart =
                            DateTime(now.year, now.month, now.day);
                        final tomorrowStart =
                            todayStart.add(const Duration(days: 1));

                        final todayEvents = allEvents.where((doc) {
                          final data = doc.data();
                          if (data is! Map<String, dynamic>) return false;
                          final dateValue = data['date'];
                          if (dateValue is! Timestamp) return false;
                          final date = dateValue.toDate();
                          return DateTime(date.year, date.month, date.day)
                              .isAtSameMomentAs(todayStart);
                        }).toList();

                        final upcomingEvents = allEvents.where((doc) {
                          final data = doc.data();
                          if (data is! Map<String, dynamic>) return false;
                          final dateValue = data['date'];
                          if (dateValue is! Timestamp) return false;
                          final date = dateValue.toDate();
                          return date.isAfter(tomorrowStart) ||
                              date.isAtSameMomentAs(tomorrowStart);
                        }).toList();

                        return ListView(
                          padding:
                              EdgeInsets.symmetric(horizontal: pagePadding),
                          children: [
                            if (todayEvents.isNotEmpty) ...[
                              _sectionTitle('Hoy tienes este evento',
                                  screenWidth, screenHeight),
                              ...todayEvents.map((doc) => _buildAgendaCard(
                                    context,
                                    doc,
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                  )),
                            ],
                            if (upcomingEvents.isNotEmpty) ...[
                              _sectionTitle('Eventos proximos', screenWidth,
                                  screenHeight),
                              ...upcomingEvents.map((doc) => _buildAgendaCard(
                                    context,
                                    doc,
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                  )),
                            ],
                            if (allEvents.isEmpty)
                              Padding(
                                padding:
                                    EdgeInsets.only(top: screenHeight * 0.1),
                                child: _emptyState(screenWidth, screenHeight),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
      child: Text(
        text,
        style: TextStyle(
          fontSize: (screenWidth * 0.045).clamp(16.0, 19.0),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required double screenWidth,
    required double screenHeight,
    required double padding,
  }) {
    final titleSize = (screenWidth * 0.085).clamp(28.0, 35.0);

    return Container(
      padding: EdgeInsets.fromLTRB(
          padding, screenHeight * 0.032, padding, screenHeight * 0.028),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Agenda',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: screenHeight * 0.007),
                Text(
                  'Tus proximos partidos y eventos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: (screenWidth * 0.04).clamp(14.0, 17.0),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: screenWidth * 0.065,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(double screenWidth, double screenHeight) {
    final iconBox = screenWidth * 0.28;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: iconBox * 0.45,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: screenHeight * 0.032),
            Text(
              'Aun no te has unido a ningun partido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (screenWidth * 0.055).clamp(19.0, 23.0),
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: screenHeight * 0.012),
            Text(
              'Cuando te unas a un evento aparecera aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: (screenWidth * 0.038).clamp(13.0, 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaCard(
    BuildContext context,
    QueryDocumentSnapshot doc, {
    required double screenWidth,
    required double screenHeight,
  }) {
    final dataRaw = doc.data();
    if (dataRaw is! Map<String, dynamic>) return const SizedBox.shrink();

    final matchId = doc.id;
    final title = dataRaw['title']?.toString() ?? 'Partido';
    final location = dataRaw['location']?.toString() ?? 'Ubicacion';
    final sport = dataRaw['sport']?.toString() ?? 'Deporte';
    final iconBox = (screenWidth * 0.155).clamp(54.0, 66.0);

    String dateStr = 'Fecha pendiente';
    String timeStr = '--:--';

    if (dataRaw['date'] is Timestamp) {
      final dateTime = (dataRaw['date'] as Timestamp).toDate();
      dateStr = DateFormat('dd MMMM', 'es').format(dateTime);
      timeStr = DateFormat('hh:mm a').format(dateTime);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmarUnirseScreen(
              matchId: matchId,
              matchData: dataRaw,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.026),
        padding: EdgeInsets.all(screenWidth * 0.055),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.07),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: screenWidth * 0.035,
              offset: Offset(0, screenHeight * 0.008),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    color: AppColors.primary,
                    size: iconBox * 0.48,
                  ),
                ),
                SizedBox(width: screenWidth * 0.045),
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
                      SizedBox(height: screenHeight * 0.007),
                      Text(
                        sport,
                        style: TextStyle(
                          fontSize: (screenWidth * 0.036).clamp(12.0, 15.0),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.032,
                      vertical: screenHeight * 0.012,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    ),
                    child: Text(
                      'Confirmado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                      ),
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: screenHeight * 0.028),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: screenWidth * 0.04, color: AppColors.primary),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    '$dateStr • $timeStr',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.018),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: screenWidth * 0.045, color: AppColors.primary),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
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
