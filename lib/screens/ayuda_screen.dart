import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  // 🔹 Función para navegar al chat de soporte (A implementar)
  void _abrirChatDeSoporte(BuildContext context) {
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo chat de soporte...')),
    );
    /* Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const SupportChatScreen())
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ayuda y Soporte',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactCard(context),
            const SizedBox(height: 34),
            const Text(
              'Preguntas Frecuentes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              '¿Cómo creo un partido?',
              'Ve a la pestaña central de "+" (Crear). Llena los datos de tu partido como deporte, fecha, hora y ubicación en el mapa. Una vez creado, otros usuarios podrán verlo y unirse.',
            ),
            _buildFaqItem(
              '¿Cómo me uno a un partido?',
              'En la pestaña principal (Inicio) o en el mapa, puedes explorar los partidos disponibles. Selecciona uno que te guste y presiona el botón de "Unirme al Partido".',
            ),
            _buildFaqItem(
              '¿Qué significa mi reputación?',
              'Tu reputación (del 1 al 5) es tu calificación global como jugador. Se basa en el respeto, puntualidad y buen comportamiento durante los encuentros. ¡Mantenla alta para ser siempre invitado!',
            ),
            _buildFaqItem(
              '¿Cómo edito mi perfil?',
              'En la pantalla de tu Perfil, presiona el botón "Editar" en la esquina superior derecha. Podrás cambiar tu nombre, nivel y deporte favorito. Para la foto, simplemente toca el ícono de la cámara en tu avatar.',
            ),
            _buildFaqItem(
              '¿Qué pasa si un creador cancela el partido?',
              'Si el creador cancela el evento, se notificará a todos los participantes unidos. No afectará tu reputación ni tu historial de partidos jugados.',
            ),
            _buildFaqItem(
              '¿Tienen acceso los administradores a mis chats?',
              'Únicamente tienen acceso al canal de "Chat de Soporte" en caso de que lo utilices para resolver algún problema. Tus mensajes privados o de grupos de partidos están protegidos.',
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 TARJETA DE CONTACTO PREMIUM CON BOTÓN DE CHAT
  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Necesitas más ayuda?',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Nuestros administradores están listos para ayudarte con cualquier problema.',
                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.3),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _abrirChatDeSoporte(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text(
                'Abrir Chat de Soporte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  // 🔹 ITEM DESPLEGABLE DE PREGUNTAS FRECUENTES
  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: Colors.grey,
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF111827)),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              answer,
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.5, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}