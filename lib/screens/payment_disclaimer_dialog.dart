import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaymentDisclaimerDialog {
  static void mostrar(BuildContext context,
      {required String organizadorNombre}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Forzar lectura del aviso corporativo
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: Row(
            children: [
              Icon(Icons.gavel_rounded, color: Colors.orangeAccent, size: 28.r),
              SizedBox(width: 12.w),
              Text('Aviso de Transparencia',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GameOn es una plataforma tecnológica exclusivamente de vinculación y organización deportiva.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                'La aplicación NO recauda, gestiona, ni se hace responsable bajo ningún concepto del dinero de inscripciones o reservas de canchas.',
                style: TextStyle(
                    color: Colors.black87, fontSize: 13.sp, height: 1.4),
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Por favor, póngase en contacto directo con el organizador ($organizadorNombre) para coordinar el pago de forma externa y segura.',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido y Aceptar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
