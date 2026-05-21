import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import 'main_navigation_screen.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../theme/colors.dart';
import '../constants/app_sports.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool obscure1 = true;
  bool obscure2 = true;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  String? selectedSport;
  String? selectedLevel;
  String? _photoUrl; // 🔹 Almacena la URL de la imagen subida

  final sports = AppSports.values;
  final levels = ['Principiante', 'Intermedio', 'Avanzado'];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 🔹 Función para seleccionar, comprimir y subir imagen ANTES del registro
  Future<void> _processAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          "${tempDir.path}/reg_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 40,
        minWidth: 600,
        minHeight: 600,
      );

      if (compressedFile != null) {
        final String? url =
            await ImageService.uploadImage(File(compressedFile.path));
        if (mounted && url != null) {
          setState(() => _photoUrl = url);
        }
      }
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al subir la imagen',
                  style: TextStyle(color: AppColors.textLight)),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        selectedSport == null ||
        selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, llena todos los campos y selecciones.')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Las contraseñas no coinciden.'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService().registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // 🔹 Guardamos también la URL de la foto en Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'sport': selectedSport,
          'level': selectedLevel,
          'photoUrl': _photoUrl,
          'role': 'user', // Rol por defecto
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message ?? 'Error al registrar usuario'),
            backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al guardar el perfil: $e'),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final pagePadding = screenWidth * 0.06;
    final headerHeight = screenHeight * 0.085;
    final inputHeight = (screenHeight * 0.064).clamp(50.0, 60.0);
    final radius = screenWidth * 0.035;
    final titleSize = (screenWidth * 0.055).clamp(18.0, 22.0);
    final labelSize = (screenWidth * 0.036).clamp(13.0, 15.0);
    final buttonTextSize = (screenWidth * 0.043).clamp(15.0, 18.0);
    final avatarSize = (screenWidth * 0.28).clamp(92.0, 120.0);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: headerHeight.h,
              padding: EdgeInsets.symmetric(horizontal: (screenWidth * 0.04).r),
              decoration: const BoxDecoration(
                color: AppColors.textLight,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Flexible(
                    child: Text(
                      'Crear Cuenta',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: titleSize.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(pagePadding.r),
                child: Column(
                  children: [
                    // 🔹 SECCIÓN DE IMAGEN ACTUALIZADA
                    Column(
                      children: [
                        GestureDetector(
                          onTap:
                              _isUploadingImage ? null : _processAndUploadImage,
                          child: Stack(
                            children: [
                              Container(
                                width: avatarSize.w,
                                height: avatarSize.h,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.textLight,
                                      width: screenWidth * 0.008),
                                ),
                                child: ClipOval(
                                  child: _isUploadingImage
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: AppColors.primary))
                                      : _photoUrl != null
                                          ? Image.network(_photoUrl!,
                                              fit: BoxFit.cover)
                                          : Center(
                                              child: Icon(Icons.person,
                                                  size: (avatarSize * 0.42).r,
                                                  color: AppColors.primary),
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: (avatarSize * 0.36).w,
                                  height: (avatarSize * 0.36).h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.textLight,
                                        width: screenWidth * 0.008),
                                  ),
                                  child: Icon(Icons.camera_alt,
                                      color: AppColors.textLight,
                                      size: (avatarSize * 0.16).r),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: (screenHeight * 0.014).h),
                        Text(
                          'Añadir foto (Opcional)',
                          style: TextStyle(
                              fontSize:
                                  (screenWidth * 0.035).clamp(12.0, 15.0).sp,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    SizedBox(height: (screenHeight * 0.035).h),
                    _label('Nombre Completo', labelSize, screenHeight),
                    _input('Nombre', _nameController, inputHeight, radius,
                        pagePadding),
                    _label('Correo Electrónico', labelSize, screenHeight),
                    _input('tu@correo.com', _emailController, inputHeight,
                        radius, pagePadding),
                    _label('Contraseña', labelSize, screenHeight),
                    _passwordInput(
                      obscure1,
                      () => setState(() => obscure1 = !obscure1),
                      _passwordController,
                      inputHeight,
                      radius,
                      pagePadding,
                    ),
                    _label('Confirmar Contraseña', labelSize, screenHeight),
                    _passwordInput(
                      obscure2,
                      () => setState(() => obscure2 = !obscure2),
                      _confirmPasswordController,
                      inputHeight,
                      radius,
                      pagePadding,
                    ),
                    _label('Deporte Preferido', labelSize, screenHeight),
                    _dropdown(sports, selectedSport, (v) {
                      setState(() => selectedSport = v);
                    }, inputHeight, radius, pagePadding),
                    _label('Nivel de Juego', labelSize, screenHeight),
                    _dropdown(levels, selectedLevel, (v) {
                      setState(() => selectedLevel = v);
                    }, inputHeight, radius, pagePadding),
                    SizedBox(height: (screenHeight * 0.03).h),
                    SizedBox(
                      width: double.infinity,
                      height: inputHeight.h,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isUploadingImage)
                            ? null
                            : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radius.r)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.textLight)
                            : Text(
                                'Completar Registro',
                                style: TextStyle(
                                    fontSize: buttonTextSize.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight),
                              ),
                      ),
                    ),
                    SizedBox(height: (screenHeight * 0.025).h),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('¿Ya tienes cuenta? ',
                            style: TextStyle(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Inicia sesión',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 WIDGETS AUXILIARES
  Widget _label(String text, double fontSize, double screenHeight) {
    return Padding(
      padding: EdgeInsets.only(
          top: (screenHeight * 0.018).r, bottom: (screenHeight * 0.007).r),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: TextStyle(
                fontSize: fontSize.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _input(String hint, TextEditingController controller, double height,
      double radius, double horizontalPadding) {
    return Container(
      height: height.h,
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(radius.r),
          color: AppColors.textLight),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: (horizontalPadding * 0.65).r)),
      ),
    );
  }

  Widget _passwordInput(
      bool obscure,
      VoidCallback toggle,
      TextEditingController controller,
      double height,
      double radius,
      double horizontalPadding) {
    return Container(
      height: height.h,
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(radius.r),
          color: AppColors.textLight),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: '********',
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: (horizontalPadding * 0.65).r),
          suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary),
              onPressed: toggle),
        ),
      ),
    );
  }

  Widget _dropdown(
      List<String> items,
      String? value,
      Function(String?) onChanged,
      double height,
      double radius,
      double horizontalPadding) {
    return Container(
      height: height.h,
      padding: EdgeInsets.symmetric(horizontal: (horizontalPadding * 0.5).r),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(radius.r),
          color: AppColors.textLight),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text('Seleccionar'),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
