import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart';
import 'main_navigation_screen.dart';
import 'login_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              user != null ? const MainNavigationScreen() : const LoginScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Error critico en LoadingScreen: $e');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final iconSize = (screenWidth * 0.25).clamp(82.0, 112.0);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: iconSize.r, color: Colors.white),
            SizedBox(height: (screenHeight * 0.028).h),
            Text(
              'Game On',
              style: TextStyle(
                fontSize: (screenWidth * 0.105).clamp(36.0, 46.0).sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: (screenHeight * 0.055).h),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
