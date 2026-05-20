import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_screen.dart';
import 'main_navigation_screen.dart';
import '../services/auth_service.dart';
import 'complete_profile_screen.dart';
import '../theme/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService().signInWithGoogle();

      if (result != null) {
        final User user = result['user'];
        final bool isNewUser = result['isNewUser'];

        if (!mounted) return;

        if (isNewUser) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(
                uid: user.uid,
                name: user.displayName ?? '',
                email: user.email ?? '',
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesion con Google: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService().loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
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
          content: Text(e.message ?? 'Error al iniciar sesion'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final horizontalPadding = screenWidth * 0.06;
    final verticalPadding = screenHeight * 0.045;
    final contentWidth = screenWidth > 620 ? screenWidth * 0.58 : screenWidth;
    final titleSize = (screenWidth * 0.12).clamp(36.0, 52.0);
    final bodySize = (screenWidth * 0.04).clamp(14.0, 17.0);
    final fieldHeight = (screenHeight * 0.065).clamp(50.0, 60.0);
    final buttonRadius = screenWidth * 0.035;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenHeight - MediaQuery.paddingOf(context).vertical,
                maxWidth: contentWidth,
              ),
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding.r,
                  vertical: verticalPadding.r,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: (screenHeight * 0.08).h),
                    Text(
                      'Game On',
                      style: TextStyle(
                        fontSize: titleSize.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: (screenHeight * 0.01).h),
                    Text(
                      'Encuentra tu partido',
                      style: TextStyle(
                        fontSize: bodySize.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: (screenHeight * 0.045).h),
                    _inputField(
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      height: fieldHeight,
                      fontSize: bodySize,
                      radius: buttonRadius,
                      horizontalPadding: horizontalPadding * 0.7,
                    ),
                    SizedBox(height: (screenHeight * 0.018).h),
                    _inputField(
                      hint: 'Contrasena',
                      icon: Icons.lock_outline,
                      obscure: true,
                      controller: _passwordController,
                      height: fieldHeight,
                      fontSize: bodySize,
                      radius: buttonRadius,
                      horizontalPadding: horizontalPadding * 0.7,
                    ),
                    SizedBox(height: (screenHeight * 0.018).h),
                    SizedBox(
                      width: double.infinity,
                      height: fieldHeight.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonRadius.r),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Iniciar Sesion',
                                    style: TextStyle(
                                      fontSize: bodySize.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: (screenWidth * 0.02).w),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: (bodySize * 1.15).r,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: (screenHeight * 0.018).h),
                    SizedBox(
                      width: double.infinity,
                      height: fieldHeight.h,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignInScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonRadius.r),
                          ),
                        ),
                        child: Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: bodySize.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF364153),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: (screenHeight * 0.022).h),
                    Center(
                      child: Text(
                        'Olvide mi contrasena',
                        style: TextStyle(
                          fontSize: bodySize.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: (screenHeight * 0.035).h),
                    Row(
                      children: [
                        const Expanded(
                            child: Divider(color: Color(0xFFE5E7EB))),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: (screenWidth * 0.03).r),
                          child: Text(
                            'O continua con',
                            style: TextStyle(
                              fontSize:
                                  (screenWidth * 0.035).clamp(12.0, 15.0).sp,
                              color: const Color(0xFF6A7282),
                            ),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: Color(0xFFE5E7EB))),
                      ],
                    ),
                    SizedBox(height: (screenHeight * 0.035).h),
                    Row(
                      children: [
                        Expanded(
                          child: _socialButton(
                            text: 'Google',
                            icon: Icons.g_mobiledata,
                            onTap: _isLoading ? null : _loginWithGoogle,
                            height: fieldHeight * 0.9,
                            fontSize: bodySize,
                            iconSize: bodySize * 2,
                            radius: buttonRadius,
                          ),
                        ),
                        SizedBox(width: (screenWidth * 0.04).w),
                        Expanded(
                          child: _socialButton(
                            text: 'Apple',
                            icon: Icons.apple,
                            onTap: () {},
                            height: fieldHeight * 0.9,
                            fontSize: bodySize,
                            iconSize: bodySize * 1.45,
                            radius: buttonRadius,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    bool obscure = false,
    required TextEditingController controller,
    required double height,
    required double fontSize,
    required double radius,
    required double horizontalPadding,
  }) {
    return Container(
      height: height.h,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(radius.r),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(fontSize: fontSize.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: fontSize.sp,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding.r,
            vertical: (height * 0.28).r,
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String text,
    required IconData icon,
    VoidCallback? onTap,
    required double height,
    required double fontSize,
    required double iconSize,
    required double radius,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height.h,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(radius.r),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize.r),
            SizedBox(width: (height * 0.16).w),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
