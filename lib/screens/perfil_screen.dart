import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../services/image_service.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String name = 'Cargando...';
  String level = 'NA';
  String favoriteSport = 'Cargando...';
  String? photoUrl;

  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        final data = doc.data();
        setState(() {
          name = data?['name'] ?? user.displayName ?? 'Usuario';
          level = data?['level'] ?? 'NA';
          favoriteSport = data?['sport'] ?? 'Voley';
          photoUrl = data?['photoUrl'] ?? user.photoURL;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processAndUploadImage() async {
    final picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final tempDir = await getTemporaryDirectory();

      final targetPath =
          "${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 40,
        minWidth: 600,
        minHeight: 600,
      );

      if (compressedFile != null) {
        final String? url = await ImageService.uploadImage(
          File(compressedFile.path),
        );

        if (url != null) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) return;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'photoUrl': url});

          if (mounted) setState(() => photoUrl = url);
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No pudimos actualizar la foto: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildAvatar(),
              const SizedBox(height: 20),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              _buildBadgeInfo(),
              const SizedBox(height: 34),
              _buildStatsSection(),
              const SizedBox(height: 26),
              _buildReputationSection(),
              const SizedBox(height: 26),
              _settingsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.05,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Editar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // AVATAR

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _isUploading ? null : _processAndUploadImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                width: 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.06,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: ClipOval(
              child: photoUrl != null
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.person,
                      size: 70,
                      color: Colors.grey,
                    ),
            ),
          ),
          if (_isUploading)
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.35,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          )
        ],
      ),
    );
  }

  // BADGES

  Widget _buildBadgeInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _badge(
          'Nivel $level 🔥',
          Colors.orange,
        ),
        const SizedBox(width: 12),
        _badge(
          favoriteSport,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _badge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // STATS

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividad',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _statCard(
            'Partidos jugados',
            '27',
            Icons.sports_soccer,
          ),
          const SizedBox(height: 16),
          _statCard(
            'Eventos creados',
            '8',
            Icons.event,
          ),
          const SizedBox(height: 16),
          _lastMatchCard(),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          )
        ],
      ),
    );
  }

  Widget _lastMatchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Último partido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Fútbol • 24 Abril 2026',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          )
        ],
      ),
    );
  }

  // REPUTACIÓN

  Widget _buildReputationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.04,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Reputación',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '4.9',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _reputationTag(
                  'Buen compañero',
                ),
                _reputationTag(
                  'Puntual',
                ),
                _reputationTag(
                  'Juego limpio',
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _reputationTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // SETTINGS

  Widget _settingsSection(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.04,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          onTap: () async {
            await AuthService().signOut();

            if (!context.mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
              (r) => false,
            );
          },
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          trailing: const Icon(
            Icons.logout_rounded,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
