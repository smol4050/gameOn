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
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final userAgendaRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('agenda').doc(widget.matchId);
    final matchRef = FirebaseFirestore.instance.collection('matches').doc(widget.matchId);

    try {
      if (_isJoined) {
        // 🔹 CANCELAR
        await userAgendaRef.delete();
        await matchRef.update({'joinedSlots': FieldValue.increment(-1)});
      } else {
        // 🔹 UNIRSE
        await userAgendaRef.set(widget.matchData);
        await matchRef.update({'joinedSlots': FieldValue.increment(1)});
      }
      _isJoined = !_isJoined;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int joined = widget.matchData['joinedSlots'] ?? 0;
    int total = widget.matchData['totalSlots'] ?? 10;
    double progress = joined / total;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(widget.matchData['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            // 🔹 BARRA DE PROGRESO
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
                style: ElevatedButton.styleFrom(backgroundColor: _isJoined ? Colors.red : Colors.green),
                onPressed: _isLoading ? null : _toggleAction,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isJoined ? 'CANCELAR ASISTENCIA' : 'CONFIRMAR Y UNIRME', style: const TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}