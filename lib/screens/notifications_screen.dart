import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notificaciones', 
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: user == null 
        ? const Center(child: Text("Inicia sesión para ver tus notificaciones"))
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .orderBy('date', descending: true) // La más reciente arriba
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error al cargar"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildNotificationCard(data);
                },
              );
            },
          ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    final DateTime date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_outlined, 
              color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? 'Notificación', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(data['message'] ?? '', 
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
                Text(DateFormat('dd MMM, hh:mm a', 'es').format(date), 
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text("No tienes notificaciones aún", 
            style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}