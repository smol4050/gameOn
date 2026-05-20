import 'package:flutter/material.dart';
import '../theme/colors.dart';

class PaymentDisclaimerDialog {
  static void mostrar(BuildContext context, {required String organizadorNombre}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Forzar lectura del aviso corporativo
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.gavel_rounded, color: Colors.orangeAccent, size: 28),
              SizedBox(width: 12),
              Text('Aviso de Transparencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GameOn es una plataforma tecnológica exclusivamente de vinculación y organización deportiva.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'La aplicación NO recauda, gestiona, ni se hace responsable bajo ningún concepto del dinero de inscripciones o reservas de canchas.',
                style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Por favor, póngase en contacto directo con el organizador ($organizadorNombre) para coordinar el pago de forma externa y segura.',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido y Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}