import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfirmarUnirseScreen extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> matchData;
  const ConfirmarUnirseScreen({super.key, required this.matchId, required this.matchData});

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
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('agenda').doc(widget.matchId).get();
    if (mounted) setState(() => _isJoined = doc.exists);
  }

Future<void> _toggleAction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final userAgendaRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('agenda').doc(widget.matchId);
    final matchRef = FirebaseFirestore.instance.collection('matches').doc(widget.matchId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot matchSnap = await transaction.get(matchRef);
        if (!matchSnap.exists) return;

        if (_isJoined) {
          transaction.delete(userAgendaRef);
          transaction.update(matchRef, {
            'joinedSlots': FieldValue.increment(-1),
          });
        } else {
          if (matchSnap['joinedSlots'] < matchSnap['totalSlots']) {
            // 1. Definir referencia
            final notificationRef = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .doc();

            // 2. 🔔 GUARDAR DATOS (Faltaba esta línea)
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

            transaction.update(matchRef, {
              'joinedSlots': FieldValue.increment(1),
            });
          }
        }
      });

      if (mounted) setState(() => _isJoined = !_isJoined);
    } catch (e) {
      debugPrint("Error en la transacción: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int joined = widget.matchData['joinedSlots'] ?? 0;
    int total = (widget.matchData['totalSlots'] ?? 10);
    // Validación para evitar división por cero
    double progress = total > 0 ? (joined / total).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(widget.matchData['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Cupos ocupados"), Text("$joined / $total")]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                color: progress > 0.8 ? Colors.red : Colors.green,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isJoined ? Colors.red : Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _toggleAction,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isJoined ? 'CANCELAR ASISTENCIA' : 'CONFIRMAR Y UNIRME', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}