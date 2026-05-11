import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/colors.dart';
import 'main_navigation_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String email;

  const CompleteProfileScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.email,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  String? _selectedSport;
  String? _selectedLevel;
  bool _isSaving = false;

  final List<String> _sports = ['Futbol', 'Baloncesto', 'Tenis', 'Padel'];
  final List<String> _levels = ['Principiante', 'Intermedio', 'Avanzado'];

  void _saveProfile() async {
    if (_selectedSport == null || _selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'uid': widget.uid,
        'name': widget.name,
        'email': widget.email,
        'sport': _selectedSport,
        'level': _selectedLevel,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final padding = screenWidth * 0.06;
    final inputHeight = (screenHeight * 0.064).clamp(50.0, 60.0);
    final radius = screenWidth * 0.035;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Casi listo',
                style: TextStyle(
                  fontSize: (screenWidth * 0.07).clamp(24.0, 30.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Hola ${widget.name}, dinos que juegas para personalizar tu experiencia.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: (screenWidth * 0.04).clamp(14.0, 17.0),
                ),
              ),
              SizedBox(height: screenHeight * 0.038),
              _buildDropdown(
                hint: 'Tu Deporte',
                value: _selectedSport,
                items: _sports,
                onChanged: (val) => setState(() => _selectedSport = val),
                height: inputHeight,
                radius: radius,
                horizontalPadding: padding,
              ),
              SizedBox(height: screenHeight * 0.024),
              _buildDropdown(
                hint: 'Tu Nivel',
                value: _selectedLevel,
                items: _levels,
                onChanged: (val) => setState(() => _selectedLevel = val),
                height: inputHeight,
                radius: radius,
                horizontalPadding: padding,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: inputHeight,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Finalizar Registro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (screenWidth * 0.04).clamp(14.0, 17.0),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required double height,
    required double radius,
    required double horizontalPadding,
  }) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.65),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
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
