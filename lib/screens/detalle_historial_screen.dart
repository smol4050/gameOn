import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';

// 🔹 LÓGICA PURA Y COMPLIANCE DE REPORTE (Aislada para pruebas unitarias)
class ReportLogic {
  static bool debeDescontarReputacion({
    required int totalReportesMismaRazon,
    required int totalAsistentes,
    double umbral = 0.70,
  }) {
    if (totalAsistentes <= 0) return false;
    return (totalReportesMismaRazon / totalAsistentes) >= umbral;
  }

  static double calcularNuevaReputacion(double reputacionActual) {
    double nueva = reputacionActual - 0.1;
    return nueva < 0.0 ? 0.0 : double.parse(nueva.toStringAsFixed(1));
  }
}

class DetalleHistorialScreen extends StatelessWidget {
  final String activityId;
  final Map<String, dynamic> activityData;

  const DetalleHistorialScreen({
    super.key,
    required this.activityId,
    required this.activityData,
  });

  void _mostrarDialogoReporte(BuildContext context, String usuarioId, String usuarioNombre, int totalAsistentes) {
    final motivos = [
      'Conducta antideportiva / Juego Sucio',
      'Falta de asistencia sin previo aviso',
      'Agresión verbal o física',
      'Identidad falsa / Perfil sospechoso',
      'Otro motivo'
    ];
    
    String motivoSeleccionado = motivos.first;
    final detallesCtrl = TextEditingController();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Validación de seguridad por si se intenta evadir la UI
    if (usuarioId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No puedes reportarte a ti mismo.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Reportar a $usuarioNombre',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selecciona el motivo del reporte:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: motivoSeleccionado,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: motivos.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => motivoSeleccionado = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Detalles adicionales (Opcional):', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: detallesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe brevemente lo sucedido...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    // 1. Registrar reporte en la base de datos
                    await FirebaseFirestore.instance.collection('reports').add({
                      'reportedUserId': usuarioId,
                      'reportedUserName': usuarioNombre,
                      'reporterUserId': currentUserId,
                      'activityId': activityId,
                      'reason': motivoSeleccionado,
                      'details': detallesCtrl.text.trim(),
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    // 2. Consultar reportes acumulados de la misma razón en esta actividad
                    final reportesQuery = await FirebaseFirestore.instance
                        .collection('reports')
                        .where('activityId', isEqualTo: activityId)
                        .where('reportedUserId', isEqualTo: usuarioId)
                        .where('reason', isEqualTo: motivoSeleccionado)
                        .get();

                    int totalReportesMismaRazon = reportesQuery.docs.length;

                    // 3. Evaluar el umbral utilizando la lógica pura
                    if (ReportLogic.debeDescontarReputacion(
                      totalReportesMismaRazon: totalReportesMismaRazon,
                      totalAsistentes: totalAsistentes,
                    )) {
                      final userDocRef = FirebaseFirestore.instance.collection('users').doc(usuarioId);
                      final userSnapshot = await userDocRef.get();

                      if (userSnapshot.exists) {
                        final userData = userSnapshot.data() ?? {};
                        double reputacionActual = double.tryParse(userData['rating']?.toString() ?? '5.0') ?? 5.0;
                        
                        double nuevaReputacion = ReportLogic.calcularNuevaReputacion(reputacionActual);
                        
                        await userDocRef.update({'rating': nuevaReputacion});
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reporte enviado. Sistema de reputación actualizado para $usuarioNombre.')),
                      );
                    }
                  },
                  child: const Text('Enviar Reporte', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = activityData['title'] ?? 'Detalles';
    final sport = activityData['sport'] ?? 'Deporte';
    final isEvent = activityData['isEvent'] == true;
    final fecha = (activityData['date'] as Timestamp).toDate();
    final dateStr = DateFormat('dd MMMM yyyy • hh:mm a', 'es').format(fecha);
    final coleccionOrigen = isEvent ? 'events' : 'matches';
    
    // Identificador del usuario logueado en el dispositivo actual
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEvent ? 'Detalle del Evento' : 'Detalle del Partido', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text('Deporte: $sport', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Finalizado el: $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text('Asistentes / Jugadores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(coleccionOrigen)
                  .doc(activityId)
                  .collection('players')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error al cargar asistentes.'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final players = snapshot.data!.docs;

                if (players.isEmpty) {
                  return const Center(child: Text('No hay registros de jugadores para esta actividad.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final pDoc = players[index];
                    final pData = pDoc.data() as Map<String, dynamic>;
                    
                    final pName = pData['name'] ?? 'Jugador Anónimo';
                    final pPhoto = pData['photoUrl'] ?? '';
                    
                    // 🔹 VALIDACIÓN: Verificar si el jugador de la fila soy yo mismo
                    final esMiPropioUsuario = pDoc.id == currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: pPhoto.isNotEmpty ? NetworkImage(pPhoto) : null,
                            child: pPhoto.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          // 🔹 INTERFAZ CONDICIONAL: Ocultar el botón si es mi propio perfil
                          if (!esMiPropioUsuario)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.08),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _mostrarDialogoReporte(context, pDoc.id, pName, players.length),
                              icon: const Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 14),
                              label: const Text('Reportar', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: const Text('Tú', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                            )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}