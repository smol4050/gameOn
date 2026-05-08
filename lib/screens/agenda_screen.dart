import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/colors.dart';
import 'confirmar_unirse_screen.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            Expanded(
              child:
                  userId == null
                      ? const Center(
                        child:
                            CircularProgressIndicator(
                              color:
                                  AppColors.primary,
                            ),
                      )
                      : StreamBuilder<
                        QuerySnapshot
                      >(
                        stream:
                            FirebaseFirestore
                                .instance
                                .collection(
                                  'users',
                                )
                                .doc(userId)
                                .collection(
                                  'agenda',
                                )
                                .orderBy(
                                  'joinedAt',
                                  descending:
                                      true,
                                )
                                .snapshots(),

                        builder: (
                          context,
                          snapshot,
                        ) {
                          if (snapshot
                                  .connectionState ==
                              ConnectionState
                                  .waiting) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(
                                    color:
                                        AppColors
                                            .primary,
                                  ),
                            );
                          }

                          if (!snapshot
                                  .hasData ||
                              snapshot
                                  .data!
                                  .docs
                                  .isEmpty) {
                            return _emptyState();
                          }

                          final myMatches =
                              snapshot
                                  .data!
                                  .docs;

                          return ListView.builder(
                            padding:
                                const EdgeInsets.all(
                                  24,
                                ),
                            itemCount:
                                myMatches.length,
                            itemBuilder: (
                              context,
                              index,
                            ) {
                              final matchId =
                                  myMatches[index]
                                      .id;

                              final data =
                                  myMatches[index]
                                          .data()
                                      as Map<
                                        String,
                                        dynamic
                                      >;

                              return _agendaCard(
                                context,
                                data,
                                matchId,
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER PREMIUM

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        28,
        24,
        24,
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Mi Agenda',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Tus próximos partidos y eventos',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // EMPTY STATE

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 50,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Aún no te has unido a ningún partido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Cuando te unas a un evento aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CARD PREMIUM

  Widget _agendaCard(
    BuildContext context,
    Map<String, dynamic> data,
    String matchId,
  ) {
    final title =
        data['title'] ?? 'Partido';

    final location =
        data['location'] ?? 'Ubicación';

    final date =
        data['date'] ?? 'Fecha';

    final time =
        data['time'] ?? '--:--';

    final sport =
        data['sport'] ?? 'Deporte';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    ConfirmarUnirseScreen(
                      matchId: matchId,
                      matchData: data,
                    ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(
          bottom: 22,
        ),

        padding: const EdgeInsets.all(22),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(30),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,

                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(
                          alpha: 0.12,
                        ),

                    borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                  ),

                  child: const Icon(
                    Icons.sports_soccer,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        title,

                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              AppColors
                                  .textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        sport,

                        style: const TextStyle(
                          fontSize: 14,
                          color:
                              AppColors
                                  .textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),

                  decoration: BoxDecoration(
                    color: AppColors.primary,

                    borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                  ),

                  child: const Text(
                    'Activo',

                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 8),

                Text(
                  '$date • $time',

                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    location,

                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      color:
                          AppColors
                              .textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,

                    decoration: BoxDecoration(
                      color: AppColors
                          .background,

                      borderRadius:
                          BorderRadius.circular(
                            20,
                          ),
                    ),

                    child: FractionallySizedBox(
                      alignment:
                          Alignment.centerLeft,

                      widthFactor: 0.75,

                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              AppColors
                                  .primary,

                          borderRadius:
                              BorderRadius.circular(
                                20,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                const Text(
                  '75%',

                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppColors.primary,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}