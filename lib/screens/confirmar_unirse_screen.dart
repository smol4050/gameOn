import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'agenda_screen.dart'; // <--- Asegúrate de importar tu pantalla de Agenda

class ConfirmarUnirseScreen extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> matchData;
  
  const ConfirmarUnirseScreen({
    super.key, 
    required this.matchId, 
    required this.matchData
  });

  @override
  State<ConfirmarUnirseScreen> createState() => _ConfirmarUnirseScreenState();
}

class _ConfirmarUnirseScreenState extends State<ConfirmarUnirseScreen> {
  bool _isJoined = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
  }

  Future<void> _checkIfJoined() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('agenda')
        .doc(widget.matchId)
        .get();
        
    if (mounted) setState(() => _isJoined = doc.exists);
  }

  Future<void> _toggleAction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final userAgendaRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('agenda').doc(widget.matchId);
    final matchRef = FirebaseFirestore.instance.collection('matches').doc(widget.matchId);

    bool newlyJoined = false;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot matchSnap = await transaction.get(matchRef);
        if (!matchSnap.exists) return;

        if (_isJoined) {
          // Cancelar asistencia
          transaction.delete(userAgendaRef);
          transaction.update(matchRef, {
            'joinedSlots': FieldValue.increment(-1),
          });
        } else {
          // Unirse
          if (matchSnap['joinedSlots'] < matchSnap['totalSlots']) {
            // 1. Notificación
            final notificationRef = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .doc();

            transaction.set(notificationRef, {
              'title': '¡Te has unido!',
              'message': 'Te has inscrito correctamente a: ${widget.matchData['title']}',
              'date': FieldValue.serverTimestamp(),
              'type': 'join',
              'read': false,
            });

            // 2. Agenda
            transaction.set(userAgendaRef, {
              'matchId': widget.matchId,
              'title': widget.matchData['title'],
              'date': widget.matchData['date'], 
              'sport': widget.matchData['sport'] ?? widget.matchData['category'],
              'location': widget.matchData['location'],
            });

            // 3. Actualizar cupos
            transaction.update(matchRef, {
              'joinedSlots': FieldValue.increment(1),
            });
            
            newlyJoined = true; // Marcamos que la acción fue unirse exitosamente
          }
        }
      });

      if (mounted) {
        setState(() => _isJoined = !_isJoined);
      }
      
    } catch (e) {
      debugPrint("Error en la transacción: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // NAVEGACIÓN A LA AGENDA
    // Si la acción fue unirse (y no cancelar), lo llevamos a la agenda
    if (newlyJoined && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AgendaScreen()),
      );
    }
  }

  // WIDGET REUTILIZABLE PARA LAS FILAS DE INFORMACIÓN (estilo UI Premium)
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1), // Ajusta el color al primario de tu app
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)
                ),
                const SizedBox(height: 4),
                Text(
                  value, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.matchData;
    
    // Extracción de datos con valores por defecto si alguno no existe en Firebase
    final title = data['title'] ?? 'Partido sin título';
    final location = data['location'] ?? 'Ubicación no especificada';
    final price = data['price']?.toString() ?? 'Gratis';
    final sport = data['sport'] ?? data['category'] ?? 'Deporte';
    final creator = data['creatorName'] ?? 'Organizador de la App'; // Ajusta la llave si es diferente

    // Formatear Fecha
    String dateStr = 'Fecha por definir';
    if (data['date'] != null && data['date'] is Timestamp) {
      final date = (data['date'] as Timestamp).toDate();
      dateStr = DateFormat('EEEE dd MMMM, hh:mm a', 'es').format(date);
    }

    // Progreso de Jugadores
    int joined = data['joinedSlots'] ?? 0;
    int total = (data['totalSlots'] ?? 10);
    double progress = total > 0 ? (joined / total).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Mismo fondo de la Agenda
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // Usamos ListView para que sea scrolleable y no se corte la info
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                children: [
                  Text(
                    title, 
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2)
                  ),
                  const SizedBox(height: 28),

                  // BLOQUE DE INFORMACIÓN
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.calendar_today_rounded, 'Fecha y Hora', dateStr),
                        _buildInfoRow(Icons.location_on_rounded, 'Ubicación', location),
                        _buildInfoRow(Icons.sports_soccer_rounded, 'Deporte', sport),
                        _buildInfoRow(Icons.attach_money_rounded, 'Costo', price),
                        _buildInfoRow(Icons.person_rounded, 'Organizado por', creator),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // SECCIÓN DE CUPOS
                  const Text("Disponibilidad de cupos", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text("$joined de $total jugadores", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)), 
                      Text("${(progress * 100).toInt()}% lleno", style: const TextStyle(fontWeight: FontWeight.bold))
                    ]
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 14,
                      color: progress >= 1.0 ? Colors.red : Colors.green,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            ),
            
            // BOTÓN FIJO EN LA PARTE INFERIOR
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ]
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isJoined ? Colors.red : Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _toggleAction,
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(
                          _isJoined ? 'CANCELAR ASISTENCIA' : 'CONFIRMAR Y UNIRME', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5)
                        ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}