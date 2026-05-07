import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfirmarUnirseScreen extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> matchData;

  const ConfirmarUnirseScreen({
    super.key,
    required this.matchId,
    required this.matchData,
  });

  @override
  State<ConfirmarUnirseScreen> createState() => _ConfirmarUnirseScreenState();
}

class _ConfirmarUnirseScreenState extends State<ConfirmarUnirseScreen> {
  bool _isLoading = false;
  bool _isAlreadyJoined = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyJoined();
  }

  // 🔹 VERIFICAR SI EL USUARIO YA ESTÁ UNIDO
  Future<void> _checkIfAlreadyJoined() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('agenda')
        .doc(widget.matchId)
        .get();

    if (doc.exists && mounted) {
      setState(() => _isAlreadyJoined = true);
    }
  }

  // 🔹 LÓGICA CENTRAL DE UNIRSE AL PARTIDO
  Future<void> _joinMatch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para unirte.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Obtener la información MÁS RECIENTE del partido para evitar errores de cupos
      DocumentSnapshot matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .get();

      if (!matchDoc.exists) throw Exception("El partido ya no existe");

      Map<String, dynamic> latestData = matchDoc.data() as Map<String, dynamic>;
      String slotsStr = latestData['slots'] ?? "0/0";
      List<String> parts = slotsStr.split('/');
      int currentFree = int.parse(parts[0]);
      int total = int.parse(parts[1]);

      if (currentFree <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ ¡Lo sentimos, ya no quedan cupos!')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // 2. Transacción en Firebase
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Actualizamos el contador global
      DocumentReference matchRef = FirebaseFirestore.instance.collection('matches').doc(widget.matchId);
      batch.update(matchRef, {'slots': '${currentFree - 1}/$total'});

      // Lo agregamos a la agenda personal del usuario
      DocumentReference agendaRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('agenda')
          .doc(widget.matchId);

      batch.set(agendaRef, {
        ...latestData,
        'joinedAt': FieldValue.serverTimestamp(),
        'slots': '${currentFree - 1}/$total',
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 ¡Te has unido al partido exitosamente!')),
      );
      
      // Cerramos la pantalla y volvemos
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al intentar unirse: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Valores por defecto
    final title = widget.matchData['title'] ?? 'Detalles del Partido';
    final location = widget.matchData['location'] ?? 'Ubicación pendiente';
    final date = widget.matchData['date'] ?? 'Fecha pendiente';
    final time = widget.matchData['time'] ?? '--:--';
    final slots = widget.matchData['slots'] ?? '0/0';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Detalles',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      // 🔻 BOTÓN FIJO ABAJO
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: (_isAlreadyJoined || _isLoading) ? null : _joinMatch,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAlreadyJoined ? Colors.grey : const Color(0xFF2E7D32),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _isAlreadyJoined ? 'Ya estás unido a este partido' : 'Unirse al Partido',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 HERO IMAGE / HEADER VISUAL
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF2E7D32).withOpacity(0.1),
              ),
              child: const Center(
                child: Icon(Icons.sports, size: 80, color: Color(0xFF2E7D32)),
              ),
            ),
            const SizedBox(height: 24),

            // 🔹 TITULO
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF101828)),
            ),
            const SizedBox(height: 24),

            // 🔹 INFO ITEMS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _InfoItem(icon: Icons.location_on, title: 'Ubicación', value: location),
                  const Divider(height: 30, color: Color(0xFFE5E7EB)),
                  _InfoItem(icon: Icons.calendar_today, title: 'Fecha', value: '$date - $time'),
                  const Divider(height: 30, color: Color(0xFFE5E7EB)),
                  _InfoItem(icon: Icons.group, title: 'Cupos Disponibles', value: slots),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 INFO ITEM (Componente Interno)
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItem({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF6A7282), fontSize: 13)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF101828))),
            ],
          ),
        ),
      ],
    );
  }
}