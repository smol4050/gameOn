import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String name = 'Isabella Londoño';
  String level = 'NA';
  String favoriteSport = 'Voley';
  String sportEmoji = '🏐';
  File? profileImage;

  final List<String> levels = ['NA', 'Principiante', 'Intermedio', 'Avanzado'];
  final Map<String, String> sports = {
    'Pádel': '🎾',
    'Voley': '🏐',
    'Fútbol': '⚽',
    'Tenis': '🎾',
    'Ultimate': '🥏',
    'Baloncesto': '🏀',
  };

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        profileImage = File(pickedImage.path);
      });
    }
  }

  void _openEditProfile() {
    String tempLevel = level;
    String tempSport = favoriteSport;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Editar perfil',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFE5E7EB),
                        backgroundImage:
                            profileImage != null ? FileImage(profileImage!) : null,
                        child: profileImage == null
                            ? const Icon(Icons.camera_alt, size: 32)
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text('Nivel de juego'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: tempLevel,
                    decoration: _inputDecoration(),
                    items: levels.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempLevel = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  const Text('Deporte preferido'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: tempSport,
                    decoration: _inputDecoration(),
                    items: sports.keys.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text('${sports[item]} $item'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempSport = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          level = tempLevel;
                          favoriteSport = tempSport;
                          sportEmoji = sports[tempSport]!;
                        });

                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Guardar cambios',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.arrow_back),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openEditProfile,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              CircleAvatar(
                radius: 56,
                backgroundColor: Colors.white,
                backgroundImage:
                    profileImage != null ? FileImage(profileImage!) : null,
                child: profileImage == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),

              const SizedBox(height: 16),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101727),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nivel: '),
                  Text(
                    '$level 🔥',
                    style: const TextStyle(
                      color: Color(0xFFF57C00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text('•'),
                  const SizedBox(width: 14),
                  const Text('Favorito: '),
                  Text(
                    '$favoriteSport $sportEmoji',
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              _activitySection(),
              const SizedBox(height: 24),
              _historySection(),
              const SizedBox(height: 24),
              _reputationSection(),
              const SizedBox(height: 24),
              _settingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activitySection() {
    return _sectionCard(
      title: 'Actividad',
      children: const [
        _ActivityItem(
          title: 'Partidos jugados',
          value: '4',
          icon: Icons.sports_volleyball,
        ),
        _ActivityItem(
          title: 'Eventos creados',
          value: '8',
          icon: Icons.emoji_events_outlined,
        ),
        _ActivityItem(
          title: 'Último partido',
          value: 'Ayer',
          icon: Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _historySection() {
    return _sectionCard(
      title: 'Historial de Partidos',
      children: const [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.check_circle, color: Color(0xFF00A63E)),
          title: Text(
            'Voley Playa',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('Miami Beach'),
          trailing: Text('Ayer'),
        ),
        Center(
          child: Text(
            'Ver todos los partidos',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _reputationSection() {
    return _sectionCard(
      title: 'Reputación',
      children: const [
        Text(
          '4.8',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101727),
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Buen compañero')),
            Chip(label: Text('Puntual')),
            Chip(label: Text('Juego limpio')),
          ],
        ),
      ],
    );
  }

  Widget _settingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withAlpha(36)),
      ),
      child: const Column(
        children: [
          ListTile(title: Text('Ayuda'), trailing: Icon(Icons.chevron_right)),
          Divider(height: 1),
          ListTile(
            title: Text('Configuración'),
            trailing: Icon(Icons.chevron_right),
          ),
          Divider(height: 1),
          ListTile(
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: Color(0xFFE7000B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withAlpha(36)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ActivityItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withAlpha(36)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF6A7282))),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Icon(icon, color: const Color(0xFF2E7D32)),
        ],
      ),
    );
  }
}