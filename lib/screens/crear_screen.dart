import 'package:flutter/material.dart';

class CrearScreen extends StatefulWidget {
  const CrearScreen({super.key});

  @override
  State<CrearScreen> createState() => _CrearScreenState();
}

class _CrearScreenState extends State<CrearScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int players = 0;
  int price = 2000;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController =
      TextEditingController(text: '2000');

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  void _changePlayers(int value) {
    setState(() {
      players += value;
      if (players < 0) players = 0;
    });
  }

  void _changePrice(int value) {
    setState(() {
      price += value;
      if (price < 0) price = 0;
      priceController.text = price.toString();
    });
  }

  String get formattedDate {
    if (selectedDate == null) return 'Seleccionar';
    return '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';
  }

  String get formattedTime {
    if (selectedTime == null) return 'Seleccionar';
    return selectedTime!.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Crear Partido',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Nombre del Partido'),
            const SizedBox(height: 8),
            _input(),

            const SizedBox(height: 24),
            const Text(
              'Selecciona el Deporte',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101727),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _SportCard(title: 'Pádel', emoji: '🎾', color: Color(0xFF1976D2)),
                  _SportCard(title: 'Voley', emoji: '🏐', color: Color(0xFFF57C00)),
                  _SportCard(title: 'Fútbol', emoji: '⚽', color: Color(0xFF2E7D32)),
                  _SportCard(title: 'Tenis', emoji: '🎾', color: Color(0xFF7D2E2E)),
                  _SportCard(title: 'Ultimate', emoji: '🥏', color: Color(0xFF542E7D)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _label('Lugar'),
            const SizedBox(height: 8),
            _mapPlaceholder(),
            const SizedBox(height: 16),

            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PlaceCard(name: 'Cancha UAO', zone: 'Sur'),
                _PlaceCard(name: 'Gol Cinco Norte', zone: 'Norte'),
                _PlaceCard(name: 'Padel Pro', zone: 'Norte'),
                _PlaceCard(name: 'Barena', zone: 'Sur'),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _dateBox(
                    title: 'Fecha',
                    value: formattedDate,
                    icon: Icons.calendar_today,
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _dateBox(
                    title: 'Hora',
                    value: formattedTime,
                    icon: Icons.access_time,
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _label('Número de Jugadores'),
            const SizedBox(height: 8),
            _counterBox(),

            const SizedBox(height: 24),
            _label('Precio por Jugador'),
            const SizedBox(height: 8),
            _priceBox(),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SizedBox(
          height: 58,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              debugPrint('Nombre: ${nameController.text}');
              debugPrint('Fecha: $formattedDate');
              debugPrint('Hora: $formattedTime');
              debugPrint('Jugadores: $players');
              debugPrint('Precio: $price');
            },
            child: const Text(
              'CREAR PARTIDO',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF364153),
      ),
    );
  }

  Widget _input() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: nameController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Escribe el nombre',
        ),
      ),
    );
  }

  Widget _mapPlaceholder() {
    return Container(
      height: 192,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(Icons.map_outlined, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _dateBox({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Color(0xFF99A1AF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _counterBox() {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _greenButton(Icons.remove, () => _changePlayers(-1)),
          const SizedBox(width: 24),
          Text(
            '$players',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 24),
          _greenButton(Icons.add, () => _changePlayers(1)),
        ],
      ),
    );
  }

  Widget _greenButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _priceBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              prefixText: '\$ ',
              suffixText: ' COP',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {
                price = int.tryParse(value) ?? 0;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _priceButton('-1000', false, () => _changePrice(-1000))),
              const SizedBox(width: 8),
              Expanded(child: _priceButton('-100', false, () => _changePrice(-100))),
              const SizedBox(width: 8),
              Expanded(child: _priceButton('+100', true, () => _changePrice(100))),
              const SizedBox(width: 8),
              Expanded(child: _priceButton('+1000', true, () => _changePrice(1000))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E7D32) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF2E7D32) : const Color(0xFFD1D5DC),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF364153),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  final String title;
  final String emoji;
  final Color color;

  const _SportCard({
    required this.title,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withAlpha(200),
            color,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final String name;
  final String zone;

  const _PlaceCard({
    required this.name,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 158,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 18,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  zone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A7282),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}