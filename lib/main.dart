import 'dart:io'; // Requerido para exit(0)
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/loading_screen.dart';
import 'screens/global_notification_wrapper.dart';
import 'screens/security_business_logic.dart';
import 'theme/colors.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppInitializationLogic {
  static ThemeData buildAppTheme() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      primaryColor: AppColors.primary,
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es', null);
  runApp(const GameOnApp());
}

class GameOnApp extends StatelessWidget {
  const GameOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializar ScreenUtil con el tamaño de diseño base (ej. iPhone 13 o tu base en Figma)
    return ScreenUtilInit(
      designSize:
          const Size(390, 844), // <-- Cambia esto por las medidas de tu diseño
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'GameOn',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          theme: AppInitializationLogic.buildAppTheme(),
          builder: (context, widget) {
            return GlobalNotificationWrapper(
              child: widget ?? const SizedBox.shrink(),
            );
          },
          home: const TermsGuardOverlay(child: LoadingScreen()),
        );
      },
    );
  }
}

// 🔹 INTERCEPTOR GLOBAL DE TÉRMINOS Y CONDICIONES LEGALES
class TermsGuardOverlay extends StatefulWidget {
  final Widget child;
  const TermsGuardOverlay({super.key, required this.child});

  @override
  State<TermsGuardOverlay> createState() => _TermsGuardOverlayState();
}

class _TermsGuardOverlayState extends State<TermsGuardOverlay> {
  bool _hasAcceptedTerms = false;
  bool _checkingCache = true;
  bool _canAccept = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkTermsStatus();
    _scrollController.addListener(_evaluarProgresoLectura);
  }

  Future<void> _checkTermsStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Leer si ya fue aceptado previamente en este dispositivo
    final status = prefs.getBool('legal_terms_accepted') ?? false;
    if (mounted) {
      setState(() {
        _hasAcceptedTerms = status;
        _checkingCache = false;
      });
    }
  }

  void _evaluarProgresoLectura() {
    if (!_scrollController.hasClients) return;

    final reachedBottom = TermsAndConditionsLogic.haLlegadoAlFinal(
      pixelsActuales: _scrollController.position.pixels,
      scrollMaximo: _scrollController.position.maxScrollExtent,
    );

    if (reachedBottom && !_canAccept) {
      setState(() => _canAccept = true);
    }
  }

  Future<void> _aceptarTerminosLegales() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('legal_terms_accepted', true);
    setState(() {
      _hasAcceptedTerms = true;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingCache) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_hasAcceptedTerms) {
      return widget.child;
    }

    // Interfaz obligatoria de Términos y Condiciones de Pantalla Completa
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.gavel_rounded, color: AppColors.primary, size: 40.r),
              SizedBox(height: 12.h),
              Text(
                'Términos y Condiciones',
                style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary),
              ),
              SizedBox(height: 8.h),
              Text(
                'Para utilizar GameOn de forma segura, es obligatorio leer el documento completo deslizando hasta el final.',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                    height: 1.4),
              ),
              SizedBox(height: 16.h),

              // 📜 CONTENEDOR LEGAL DE TEXTO CON SCROLL CONTROLADO
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. DESLINDE DE RESPONSABILIDAD FINANCIERA',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        SizedBox(height: 6.h),
                        Text(
                          'GameOn funciona única y exclusivamente como una red tecnológica para conectar deportistas y agendar canchas en Cali, Colombia. Bajo ningún supuesto la aplicación o sus desarrolladores recaudan, custodian ni administran fondos monetarios relacionados con el valor de los partidos, torneos o eventos creados por los usuarios.',
                          style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.5,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 14.h),
                        Text('2. RELACIÓN ENTRE PARTICIPANTES',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        SizedBox(height: 6.h),
                        Text(
                          'Toda transacción económica vinculada a un evento con costo se ejecutará externamente de mutuo acuerdo entre el usuario inscrito y el organizador designado. GameOn carece de facultades de mediación bancaria y no responderá ante fraudes, inasistencias o incumplimientos financieros de terceros.',
                          style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.5,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 14.h),
                        Text('3. CONDUCTA DEPORTIVA Y REPUTACIÓN',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        SizedBox(height: 6.h),
                        Text(
                          'Los usuarios aceptan someterse al sistema de reputación comunitaria. Reportes acumulados que representen el 70% o más de los asistentes de una actividad por malas conductas, faltas de respeto o agresiones derivarán automáticamente en penalizaciones y reducciones directas del score en su perfil público.',
                          style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.5,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 14.h),
                        Text('4. USO DE GEOLOCALIZACIÓN Y DATOS',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        SizedBox(height: 6.h),
                        Text(
                          'Al activar el mapa interactivo de Mapbox, usted consiente el uso temporal de su posición geográfica para ubicar centros deportivos y canchas cercanas de forma óptima.',
                          style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.5,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 20.h),
                        Center(
                          child: Text(
                            '--- Fin del Documento ---',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // 🔘 PANEL DE BOTONES
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: EdgeInsets.symmetric(vertical: 16.r),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                      ),
                      onPressed: () => exit(
                          0), // Rechazar cierra inmediatamente el aplicativo
                      child: const Text('RECHAZAR',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 16.r),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                      ),
                      // Deshabilitado hasta que se cumpla la validación de lectura completa
                      onPressed: _canAccept ? _aceptarTerminosLegales : null,
                      child: Text(
                        'CONTINUAR',
                        style: TextStyle(
                          color:
                              _canAccept ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
