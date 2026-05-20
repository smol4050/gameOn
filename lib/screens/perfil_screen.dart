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
import 'user_badge_name.dart';
import 'ayuda_screen.dart';
import 'historial_screen.dart'; // 🔹 Importamos la nueva pantalla

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
  String? role;
  
  String rating = '5.0';
  List<String> reputationTags = ['Buen compañero', 'Puntual', 'Juego limpio'];
  int matchesPlayed = 0;
  int eventsParticipated = 0;
  Map<String, dynamic>? lastMatch;

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

      final agendaRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('agenda')
          .get();

      int mCount = agendaRef.docs.length;
      Map<String, dynamic>? lMatch;
      
      if (mCount > 0) {
        lMatch = agendaRef.docs.last.data(); 
      }

      if (mounted) {
        final data = doc.data() ?? {};
        setState(() {
          name = data['name'] ?? user.displayName ?? 'Usuario';
          level = data['level'] ?? 'NA';
          role = data['role']?.toString();
          favoriteSport = data['sport'] ?? 'Fútbol';
          photoUrl = data['photoUrl'] ?? user.photoURL;
          
          rating = data['rating']?.toString() ?? '5.0';
          if (data['reputationTags'] != null) {
            reputationTags = List<String>.from(data['reputationTags']);
          }
          eventsParticipated = data['eventsParticipated'] ?? 0;
          
          matchesPlayed = mCount;
          lastMatch = lMatch;

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
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = "${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 40,
        minWidth: 600,
        minHeight: 600,
      );

      if (compressedFile != null) {
        final String? url = await ImageService.uploadImage(File(compressedFile.path));
        if (url != null) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({'photoUrl': url});
            if (mounted) setState(() => photoUrl = url);
          }
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: name);
    String tempSport = favoriteSport;
    String tempLevel = level;

    if (!['Principiante', 'Intermedio', 'Avanzado', 'Pro'].contains(tempLevel)) {
      tempLevel = 'Intermedio';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: tempSport,
                      decoration: InputDecoration(
                        labelText: 'Deporte Favorito',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Fútbol', 'Baloncesto', 'Tenis', 'Vóley', 'Ultimate']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setStateDialog(() => tempSport = val!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: tempLevel,
                      decoration: InputDecoration(
                        labelText: 'Nivel',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Principiante', 'Intermedio', 'Avanzado', 'Pro']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setStateDialog(() => tempLevel = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'name': nameCtrl.text.trim(),
                        'sport': tempSport,
                        'level': tempLevel,
                      });
                      setState(() {
                        name = nameCtrl.text.trim();
                        favoriteSport = tempSport;
                        level = tempLevel;
                      });
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
              UserBadgeName(
                name: name,
                role: role,
                textStyle: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                iconSize: 28.0,
              ),
              const SizedBox(height: 10),
              _buildBadgeInfo(),
              const SizedBox(height: 34),
              _buildStatsSection(context), // 🔹 Pasamos context para navegar
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

  // 🔹 HEADER MODIFICADO (Botón de volver eliminado)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Alinea el botón de Editar a la derecha
        children: [
          GestureDetector(
            onTap: _showEditProfileDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Editar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

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
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl!.isNotEmpty
                  ? Image.network(photoUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.person, size: 70, color: Colors.grey),
            ),
          ),
          if (_isUploading)
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadgeInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _badge('Nivel $level 🔥', Colors.orange),
        const SizedBox(width: 12),
        _badge(favoriteSport, Colors.blue),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }

  // 🔹 STATS (Hacemos las tarjetas interactivas)
  Widget _buildStatsSection(BuildContext context) {
    // Definimos la acción que abrirá el historial
    void abrirHistorial() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistorialScreen()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actividad', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _statCard('Partidos jugados', matchesPlayed.toString(), Icons.sports_soccer, abrirHistorial),
          const SizedBox(height: 16),
          _statCard('Eventos participados', eventsParticipated.toString(), Icons.emoji_events_rounded, abrirHistorial),
          const SizedBox(height: 16),
          _lastMatchCard(abrirHistorial),
        ],
      ),
    );
  }

  // 🔹 Se añadió GestureDetector a la tarjeta
  Widget _statCard(String title, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))
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
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary))
          ],
        ),
      ),
    );
  }

  // 🔹 Se añadió GestureDetector a la tarjeta
  Widget _lastMatchCard(VoidCallback onTap) {
    String sportText = favoriteSport;
    String dateText = 'Aún no has jugado';

    if (lastMatch != null) {
      sportText = lastMatch!['sport'] ?? sportText;
      if (lastMatch!['date'] is Timestamp) {
        final dateObj = (lastMatch!['date'] as Timestamp).toDate();
        dateText = "${dateObj.day}/${dateObj.month}/${dateObj.year}";
      } else {
        dateText = lastMatch!['date']?.toString() ?? 'Fecha desconocida';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Último partido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text('$sportText • $dateText', style: const TextStyle(color: AppColors.textSecondary))
          ],
        ),
      ),
    );
  }

  Widget _buildReputationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          children: [
            const Text('Reputación', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Text(rating, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _settingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AyudaScreen()));
              },
              title: const Text('Ayuda y Soporte', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 17)),
              trailing: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
            ),
            const Divider(height: 1, indent: 24, endIndent: 24, color: Color(0xFFF3F4F6)),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              onTap: () async {
                await AuthService().signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              },
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 17)),
              trailing: const Icon(Icons.logout_rounded, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}