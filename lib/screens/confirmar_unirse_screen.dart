import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'main_navigation_screen.dart'; // 👈 IMPORTANTE: Usamos la navegación principal

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
    
    // 👈 NUEVO: Referencia al jugador dentro de la subcolección del partido
    final playerRef = FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('players').doc(user.uid);

    bool newlyJoined = false;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot matchSnap = await transaction.get(matchRef);
        if (!matchSnap.exists) return;

        if (_isJoined) {
          // Cancelar asistencia
          transaction.delete(userAgendaRef);
          transaction.delete(playerRef); // 👈 Eliminamos al jugador de la lista
          transaction.update(matchRef, {
            'joinedSlots': FieldValue.increment(-1),
          });
        } else {
          // Unirse
          if (matchSnap['joinedSlots'] < matchSnap['totalSlots']) {
            final notificationRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').doc();

            transaction.set(notificationRef, {
              'title': '¡Te has unido!',
              'message': 'Te has inscrito correctamente a: ${widget.matchData['title']}',
              'date': FieldValue.serverTimestamp(),
              'type': 'join',
              'read': false,
            });

            transaction.set(userAgendaRef, {
              'matchId': widget.matchId,
              'title': widget.matchData['title'],
              'date': widget.matchData['date'], 
              'sport': widget.matchData['sport'] ?? widget.matchData['category'],
              'location': widget.matchData['location'],
            });

            // 👈 NUEVO: Guardamos el perfil del jugador en el partido
            transaction.set(playerRef, {
              'name': user.displayName ?? 'Jugador',
              'photoUrl': user.photoURL ?? '',
              'rating': 5.0, // Rating inicial por defecto
              'joinedAt': FieldValue.serverTimestamp(),
            });

            transaction.update(matchRef, {
              'joinedSlots': FieldValue.increment(1),
            });
            
            newlyJoined = true;
          }
        }
      });

      if (mounted) setState(() => _isJoined = !_isJoined);
      
    } catch (e) {
      debugPrint("Error en la transacción: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // 🚀 MAGIA DE NAVEGACIÓN: Llevamos a la Agenda CON el NavBar
    if (newlyJoined && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 2)), // 2 = Agenda
        (route) => false,
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ⭐️ NUEVO: Tarjeta de Jugador Premium
  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final name = player['name'] ?? 'Jugador';
    final photoUrl = player['photoUrl'] ?? '';
    final rating = (player['rating'] ?? 5.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.green.shade50,
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.green) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.green, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Iniciando chat con $name...')));
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.matchData;
    final title = data['title'] ?? 'Partido sin título';
    final location = data['location'] ?? 'Ubicación no especificada';
    final price = data['price']?.toString() ?? 'Gratis';
    final sport = data['sport'] ?? data['category'] ?? 'Deporte';
    final creator = data['creatorName'] ?? 'Organizador de la App';

    String dateStr = 'Fecha por definir';
    if (data['date'] != null && data['date'] is Timestamp) {
      final date = (data['date'] as Timestamp).toDate();
      dateStr = DateFormat('EEEE dd MMMM, hh:mm a', 'es').format(date);
    }

    int joined = data['joinedSlots'] ?? 0;
    int total = (data['totalSlots'] ?? 10);
    double progress = total > 0 ? (joined / total).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFFF5F7FA), elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                children: [
                  Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2)),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
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

                  // 👥 NUEVO: LISTA DE JUGADORES EN TIEMPO REAL
                  const SizedBox(height: 30),
                  const Text("Jugadores Inscritos", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('players').orderBy('joinedAt').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      if (snapshot.data!.docs.isEmpty) return const Text("Sé el primero en unirte", style: TextStyle(color: Colors.grey));
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var player = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          return _buildPlayerCard(player);
                        }
                      );
                    }
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
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
                      : Text(_isJoined ? 'CANCELAR ASISTENCIA' : 'CONFIRMAR Y UNIRME', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
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