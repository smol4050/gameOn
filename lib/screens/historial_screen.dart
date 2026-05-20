import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import 'detalle_historial_screen.dart';

// 🔹 LÓGICA PURA DE FILTRADO (Extraída para facilitar pruebas unitarias)
class HistorialLogic {
  static List<QueryDocumentSnapshot> filtrarYClasificar({
    required List<QueryDocumentSnapshot> documentos,
    required DateTime fechaActual,
    required bool obtenerEventos,
  }) {
    return documentos.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Validar si tiene fecha válida
      if (data['date'] is! Timestamp) return false;
      final fechaPartido = (data['date'] as Timestamp).toDate();
      
      // Condición 1: Solo mostrar los que YA se jugaron (pasados)
      final yaSeJugo = fechaPartido.isBefore(fechaActual);
      
      // Condición 2: Clasificar según el Tab activo (isEvent)
      final esEvento = data['isEvent'] == true;
      
      return yaSeJugo && (obtenerEventos ? esEvento : !esEvento);
    }).toList();
  }
}

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: const Text(
            'Mi Historial',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 22),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.sports_soccer), text: 'Partidos'),
              Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Eventos'),
            ],
          ),
        ),
        body: user == null
            ? const Center(child: Text('Inicia sesión para ver tu actividad.'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('agenda')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error al cargar el historial.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  final todosLosDocs = snapshot.data!.docs;

                  return TabBarView(
                    children: [
                      // TAB 1: PARTIDOS JUGADOS
                      _buildListadoCategoria(
                        documentos: HistorialLogic.filtrarYClasificar(
                          documentos: todosLosDocs,
                          fechaActual: DateTime.now(),
                          obtenerEventos: false,
                        ),
                        mensajeVacio: 'No tienes partidos jugados registrados.',
                      ),
                      // TAB 2: EVENTOS PARTICIPADOS
                      _buildListadoCategoria(
                        documentos: HistorialLogic.filtrarYClasificar(
                          documentos: todosLosDocs,
                          fechaActual: DateTime.now(),
                          obtenerEventos: true,
                        ),
                        mensajeVacio: 'No tienes eventos finalizados registrados.',
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildListadoCategoria({
    required List<QueryDocumentSnapshot> documentos,
    required String mensajeVacio,
  }) {
    if (documentos.isEmpty) {
      return Center(
        child: Text(mensajeVacio, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: documentos.length,
      itemBuilder: (context, index) {
        final doc = documentos[index];
        final data = doc.data() as Map<String, dynamic>;
        
        final title = data['title'] ?? 'Sin título';
        final sport = data['sport'] ?? 'Deporte';
        final fecha = (data['date'] as Timestamp).toDate();
        final dateStr = DateFormat('dd MMM yyyy • hh:mm a', 'es').format(fecha);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(data['isEvent'] == true ? Icons.emoji_events : Icons.sports, color: AppColors.primary),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('$sport • $dateStr', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalleHistorialScreen(
                    activityId: doc.id,
                    activityData: data,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}