import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'main_navigation_screen.dart';

class CrearScreen extends StatefulWidget {
  const CrearScreen({super.key});

  @override
  State<CrearScreen> createState() => _CrearScreenState();
}

class _CrearScreenState extends State<CrearScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int players = 10;
  int price = 2000;
  bool _isLoading = false;
  bool _isLoadingVenues = true;

  String? _selectedSport;
  String? _selectedLocation;
  String? _selectedZone;
  final String _searchQuery = "";

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController(text: '2000');

  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  List<Map<String, dynamic>> _venues = [];

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(
        "pk.eyJ1Ijoic21vbDQwNTAiLCJhIjoiY21ueXh0djNjMDc3eDJxcG1hdjJ3cHE0eSJ9.zcn7z1InAFd0DwiVFSUTSA");
    _fetchCanchasDesdeFirebase();
  }

  Future<void> _fetchCanchasDesdeFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('canchas').get();

      if (snapshot.docs.isEmpty) {
        await _subirCanchasPorDefecto();
        final newSnapshot = await FirebaseFirestore.instance.collection('canchas').get();
        if (!mounted) return;
        setState(() {
          _venues = newSnapshot.docs.map((doc) => doc.data()).toList();
          _isLoadingVenues = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _venues = snapshot.docs.map((doc) => doc.data()).toList();
          _isLoadingVenues = false;
        });
      }

      if (pointAnnotationManager != null) {
        _updateMapMarkers();
      }
    } catch (e) {
      debugPrint("Error al cargar canchas: $e");
      if (mounted) setState(() => _isLoadingVenues = false);
    }
  }

  void _abrirMapaCompleto() async {
    final selectedVenue = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapaPantallaCompletaScreen(
          venues: _venues,
          selectedSport: _selectedSport,
          selectedZone: _selectedZone,
        ),
      ),
    );

    if (!mounted) return;
    if (selectedVenue != null) {
      setState(() {
        _selectedLocation = selectedVenue['name'];
      });

      mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(selectedVenue['lng'] as num, selectedVenue['lat'] as num)),
            zoom: 14.5,
            pitch: 45.0,
          ),
          MapAnimationOptions(duration: 1500));
    }
  }

  Future<void> _subirCanchasPorDefecto() async {
    final List<Map<String, dynamic>> defaultVenues = [
      {'name': 'EL Monumental Cali', 'sport': 'Fútbol', 'zone': 'Norte', 'lat': 3.4800, 'lng': -76.5150},
      {'name': 'Fútbol 5 La Primera', 'sport': 'Fútbol', 'zone': 'Norte', 'lat': 3.4750, 'lng': -76.5100},
      {'name': 'Centro Deportivo Las Palmas', 'sport': 'Fútbol', 'zone': 'Sur', 'lat': 3.3800, 'lng': -76.5350},
      {'name': 'Complejo Deportivo 5-0', 'sport': 'Fútbol', 'zone': 'Sur', 'lat': 3.3750, 'lng': -76.5300},
      {'name': 'Pascual Obrero', 'sport': 'Fútbol', 'zone': 'Centro', 'lat': 3.4450, 'lng': -76.5250},
      {'name': 'Canchas Panamericana', 'sport': 'Fútbol', 'zone': 'Centro', 'lat': 3.4350, 'lng': -76.5350},
      {'name': 'SAN SIRO Sintéticas', 'sport': 'Fútbol', 'zone': 'Oriente', 'lat': 3.4200, 'lng': -76.4950},
      {'name': 'Canchas La 14 Oriente', 'sport': 'Fútbol', 'zone': 'Oriente', 'lat': 3.4250, 'lng': -76.4900},
      {'name': 'Canchas Bellavista Sport', 'sport': 'Fútbol', 'zone': 'Occidente', 'lat': 3.4550, 'lng': -76.5500},
      {'name': 'Canchas Los Cristales', 'sport': 'Fútbol', 'zone': 'Occidente', 'lat': 3.4450, 'lng': -76.5600},
      {'name': 'Parque Los Álamos (Público)', 'sport': 'Ultimate', 'zone': 'Norte', 'lat': 3.4930, 'lng': -76.5050},
      {'name': 'Parque La Cascada (Público)', 'sport': 'Ultimate', 'zone': 'Sur', 'lat': 3.4187, 'lng': -76.5473},
      {'name': 'Cancha de la 66 (Público)', 'sport': 'Ultimate', 'zone': 'Sur', 'lat': 3.3985, 'lng': -76.5362},
      {'name': 'Cancha de la 70 (Público)', 'sport': 'Ultimate', 'zone': 'Norte', 'lat': 3.4682, 'lng': -76.4951},
      {'name': 'Canchas Univalle', 'sport': 'Ultimate', 'zone': 'Sur', 'lat': 3.3766, 'lng': -76.5332},
      {'name': 'Coliseo Evangelista Mora', 'sport': 'Vóley', 'zone': 'Centro', 'lat': 3.4300, 'lng': -76.5350},
      {'name': 'Club Deportivo Oeste Vóley', 'sport': 'Vóley', 'zone': 'Occidente', 'lat': 3.4520, 'lng': -76.5480},
      {'name': 'Arena Vóley Cali', 'sport': 'Vóley', 'zone': 'Oriente', 'lat': 3.4050, 'lng': -76.4950},
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (var venue in defaultVenues) {
      final docRef = FirebaseFirestore.instance.collection('canchas').doc();
      batch.set(docRef, venue);
    }
    await batch.commit();
    debugPrint("✅ Canchas subidas a Firebase correctamente");
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      nameController.text.isNotEmpty && selectedDate != null && selectedTime != null && _selectedSport != null && _selectedLocation != null;

  List<Map<String, dynamic>> get _filteredVenues {
    return _venues.where((venue) {
      bool sportMatch = false;
      if (_selectedSport == null) {
        sportMatch = true;
      } else if (_selectedSport == 'Ultimate') {
        sportMatch = (venue['sport'] == 'Ultimate' || venue['sport'] == 'Fútbol');
      } else {
        sportMatch = venue['sport'] == _selectedSport;
      }
      final zoneMatch = _selectedZone == null || venue['zone'] == _selectedZone;
      final searchMatch = venue['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return sportMatch && zoneMatch && searchMatch;
    }).toList();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    mapboxMap.setCamera(CameraOptions(center: Point(coordinates: Position(-76.5227, 3.3536)), zoom: 13.5, pitch: 45.0, bearing: -17.0));

    mapboxMap.loadStyleURI(MapboxStyles.MAPBOX_STREETS).then((_) {
      _add3DBuildings();

      mapboxMap.annotations.createPointAnnotationManager().then((manager) {
        pointAnnotationManager = manager;
        pointAnnotationManager!.tapEvents(onTap:(annotation) {
          final lat = annotation.geometry.coordinates.lat;
          final lng = annotation.geometry.coordinates.lng;
          final clickedVenue = _venues.firstWhere((v) => v['lat'] == lat && v['lng'] == lng, orElse: () => <String, dynamic>{});
          if (clickedVenue.isEmpty) return;

          setState(() => _selectedLocation = clickedVenue['name']);
          mapboxMap.flyTo(CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 16.5, pitch: 60.0), MapAnimationOptions(duration: 1500));
        });

        if (!_isLoadingVenues) _updateMapMarkers();
      });
    });
  }

  Future<void> _add3DBuildings() async {
    try {
      await mapboxMap?.style.addLayer(FillExtrusionLayer(
        id: "3d-buildings", sourceId: "composite", sourceLayer: "building", minZoom: 15.0,
        filter: ["==", "extrude", "true"], fillExtrusionColor: Colors.grey.toARGB32(),
        fillExtrusionOpacity: 0.6, fillExtrusionHeight: 30.0, fillExtrusionBase: 0.0,
      ));
    } catch (e) {
      debugPrint("Error al cargar capa 3D: $e");
    }
  }

  // 🔹 GENERADOR DE PIN EN MEMORIA
  Future<Uint8List> _crearPinRojo() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 90.0;
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.location_on.codePoint),
      style: TextStyle(fontSize: size, fontFamily: Icons.location_on.fontFamily, color: Colors.red),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0.0, 0.0));
    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _updateMapMarkers() async {
    if (pointAnnotationManager == null) return;
    await pointAnnotationManager!.deleteAll();

    final Uint8List pinImage = await _crearPinRojo();

    List<PointAnnotationOptions> options = _filteredVenues.map((v) {
      return PointAnnotationOptions(
        geometry: Point(coordinates: Position((v['lng'] ?? 0).toDouble(), (v['lat'] ?? 0).toDouble())),
        image: pinImage,
        iconSize: 0.8,
        iconAnchor: IconAnchor.BOTTOM,
        textField: v['name'],
        textSize: 14.0,
        textOffset: [0.0, 0.5],
        textColor: Colors.black.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 3.0,
      );
    }).toList();

    if (options.isNotEmpty) {
      await pointAnnotationManager!.createMulti(options);
      if (_filteredVenues.isNotEmpty && mapboxMap != null) {
        mapboxMap!.flyTo(
            CameraOptions(center: Point(coordinates: Position((_filteredVenues[0]['lng'] ?? 0).toDouble(), (_filteredVenues[0]['lat'] ?? 0).toDouble())), zoom: 13.5, pitch: 45.0),
            MapAnimationOptions(duration: 1200));
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _crearPartido() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesion para crear un partido.')));
        return;
      }
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final dbName = userData?['name'];
      final dbPhoto = userData?['photoUrl'];
      final creatorName = dbName is String && dbName.isNotEmpty ? dbName : currentUser.displayName ?? 'Organizador';
      final creatorPhotoUrl = dbPhoto is String && dbPhoto.isNotEmpty ? dbPhoto : currentUser.photoURL ?? '';
      final creatorId = currentUser.uid;

      final DateTime fullDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);

      final firestore = FirebaseFirestore.instance;
      final matchRef = firestore.collection('matches').doc();
      final userAgendaRef = firestore.collection('users').doc(creatorId).collection('agenda').doc(matchRef.id);
      final playerRef = matchRef.collection('players').doc(creatorId);
      final batch = firestore.batch();

      batch.set(matchRef, {
        'title': nameController.text.trim(), 'sport': _selectedSport, 'location': _selectedLocation,
        'date': Timestamp.fromDate(fullDateTime), 'joinedSlots': 1, 'totalSlots': players, 'price': price,
        'createdAt': FieldValue.serverTimestamp(), 'creatorName': creatorName, 'creatorId': creatorId,
      });

      batch.set(userAgendaRef, {
        'matchId': matchRef.id, 'title': nameController.text.trim(), 'date': Timestamp.fromDate(fullDateTime),
        'sport': _selectedSport, 'location': _selectedLocation,
      });

      batch.set(playerRef, {
        'name': creatorName, 'email': currentUser.email ?? '', 'photoUrl': creatorPhotoUrl,
        'rating': 5.0, 'joinedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partido creado y publicado'), backgroundColor: Colors.green));
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainNavigationScreen(initialIndex: 2)), (route) => false);
    } catch (e) {
      debugPrint("Error al crear partido: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Crear Partido', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: _isLoadingVenues
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Nombre del Partido'),
                  const SizedBox(height: 8),
                  _input(),

                  const SizedBox(height: 24),
                  _label('Selecciona el Deporte'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['Fútbol', 'Baloncesto', 'Tenis', 'Ultimate', 'Vóley'].map((sport) {
                        final emojis = {'Fútbol': '⚽', 'Baloncesto': '🏀', 'Tenis': '🎾', 'Ultimate': '🥏', 'Vóley': '🏐'};
                        final colors = {'Fútbol': Colors.green, 'Baloncesto': Colors.orange, 'Tenis': Colors.red, 'Ultimate': Colors.blue, 'Vóley': Colors.deepPurple};
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSport = sport;
                              _selectedLocation = null;
                            });
                            _updateMapMarkers();
                          },
                          child: _SportCard(title: sport, emoji: emojis[sport]!, color: colors[sport]!, isSelected: _selectedSport == sport),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Lugar del Partido'),
                      if (_selectedLocation != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(_selectedLocation!, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Norte', 'Sur', 'Centro', 'Oriente', 'Occidente'].map((zone) {
                        final isSelected = _selectedZone == zone;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(zone, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected, selectedColor: const Color(0xFF2E7D32), backgroundColor: Colors.white,
                            onSelected: (selected) {
                              setState(() => _selectedZone = selected ? zone : null);
                              _updateMapMarkers();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: _abrirMapaCompleto,
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB), width: 2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15)]),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          AbsorbPointer(
                            child: MapWidget(
                              key: const ValueKey("mapboxMap_small"), styleUri: MapboxStyles.MAPBOX_STREETS,
                              onMapCreated: (MapboxMap map) {
                                _onMapCreated(map);
                                map.compass.updateSettings(CompassSettings(enabled: false));
                                map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
                              },
                            ),
                          ),
                          Positioned(
                            top: 15, left: 15, right: 15,
                            child: Container(
                              height: 45, padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                              child: const Row(children: [Icon(Icons.search, color: Colors.green), SizedBox(width: 10), Text('Toca para buscar en pantalla completa...', style: TextStyle(color: Colors.grey, fontSize: 13))]),
                            ),
                          ),
                          Positioned(
                            bottom: 10, right: 10,
                            child: FloatingActionButton.small(heroTag: "expandBtn", backgroundColor: Colors.black87, onPressed: _abrirMapaCompleto, child: const Icon(Icons.fullscreen, color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _dateBox(title: 'Fecha', value: selectedDate == null ? 'Seleccionar' : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}', icon: Icons.calendar_today, onTap: _selectDate)),
                      const SizedBox(width: 16),
                      Expanded(child: _dateBox(title: 'Hora', value: selectedTime == null ? 'Seleccionar' : selectedTime!.format(context), icon: Icons.access_time, onTap: _selectTime)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _label('Número de Jugadores'),
                  _counterBox(),

                  const SizedBox(height: 24),
                  _label('Precio por Jugador'),
                  _priceBox(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: SizedBox(
        height: 58,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), disabledBackgroundColor: Colors.grey.shade300, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: (_isLoading || !_isFormValid) ? null : _crearPartido,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isFormValid ? 'CREAR PARTIDO' : 'COMPLETE TODOS LOS CAMPOS PARA CREAR', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF364153))));

  Widget _input() => Container(
        height: 54, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(14)),
        child: TextField(controller: nameController, onChanged: (_) => setState(() {}), decoration: const InputDecoration(border: InputBorder.none, hintText: 'Escribe el nombre')),
      );

  Widget _dateBox({required String title, required String value, required IconData icon, required VoidCallback onTap}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(title),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 54, padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 12), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]),
            ),
          ),
        ],
      );

  Widget _counterBox() => Container(
        height: 70, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _circleBtn(Icons.remove, () => setState(() { players--; if (players < 1) players = 1; })),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Text('$players', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          _circleBtn(Icons.add, () => setState(() => players++)),
        ]),
      );

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20)));

  Widget _priceBox() => Container(
        padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(14)),
        child: TextField(
          controller: priceController, keyboardType: TextInputType.number, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
          decoration: const InputDecoration(prefixText: '\$ ', suffixText: ' COP', border: InputBorder.none),
          onChanged: (v) => price = int.tryParse(v) ?? 0,
        ),
      );
}

class _SportCard extends StatelessWidget {
  final String title, emoji;
  final Color color;
  final bool isSelected;
  const _SportCard({required this.title, required this.emoji, required this.color, required this.isSelected});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: isSelected ? color : Colors.white, border: Border.all(color: isSelected ? color : const Color(0xFFE5E7EB), width: 2)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(emoji, style: const TextStyle(fontSize: 28)), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87))]),
    );
  }
}

class MapaPantallaCompletaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> venues;
  final String? selectedSport;
  final String? selectedZone;

  const MapaPantallaCompletaScreen({super.key, required this.venues, this.selectedSport, this.selectedZone});

  @override
  State<MapaPantallaCompletaScreen> createState() => _MapaPantallaCompletaScreenState();
}

class _MapaPantallaCompletaScreenState extends State<MapaPantallaCompletaScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  String _searchQuery = "";
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredVenues {
    return widget.venues.where((venue) {
      bool sportMatch = widget.selectedSport == null || (widget.selectedSport == 'Ultimate' ? (venue['sport'] == 'Ultimate' || venue['sport'] == 'Fútbol') : venue['sport'] == widget.selectedSport);
      bool zoneMatch = widget.selectedZone == null || venue['zone'] == widget.selectedZone;
      bool searchMatch = venue['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return sportMatch && zoneMatch && searchMatch;
    }).toList();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.setCamera(CameraOptions(center: Point(coordinates: Position(-76.5227, 3.3536)), zoom: 13.0, pitch: 45.0));

    mapboxMap.loadStyleURI(MapboxStyles.MAPBOX_STREETS).then((_) {
      mapboxMap.style.addLayer(FillExtrusionLayer(
        id: "3d-buildings", sourceId: "composite", sourceLayer: "building", minZoom: 15.0,
        filter: ["==", "extrude", "true"], fillExtrusionColor: Colors.grey.toARGB32(),
        fillExtrusionOpacity: 0.6, fillExtrusionHeight: 30.0, fillExtrusionBase: 0.0,
      ));

      mapboxMap.annotations.createPointAnnotationManager().then((manager) {
        pointAnnotationManager = manager;
        pointAnnotationManager!.tapEvents(onTap:(annotation) {
          final lat = annotation.geometry.coordinates.lat;
          final lng = annotation.geometry.coordinates.lng;
          final clickedVenue = widget.venues.firstWhere((v) => v['lat'] == lat && v['lng'] == lng, orElse: () => <String, dynamic>{});
          if (clickedVenue.isEmpty) return;

          mapboxMap.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(lng, lat)), 
              zoom: 16.5, 
              pitch: 60.0
            ), 
            MapAnimationOptions(duration: 1200)
          );
          _mostrarTarjetaCancha(clickedVenue);
        });
        _updateMapMarkers();
      });
    });
  }

  Future<Uint8List> _crearPinRojo() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 90.0;
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.location_on.codePoint),
      style: TextStyle(fontSize: size, fontFamily: Icons.location_on.fontFamily, color: Colors.red),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0.0, 0.0));
    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _updateMapMarkers() async {
    if (pointAnnotationManager == null) return;
    await pointAnnotationManager!.deleteAll();

    final Uint8List pinImage = await _crearPinRojo();

    List<PointAnnotationOptions> options = _filteredVenues.map((v) {
      return PointAnnotationOptions(
        geometry: Point(coordinates: Position((v['lng'] ?? 0).toDouble(), (v['lat'] ?? 0).toDouble())),
        image: pinImage,
        iconSize: 0.8,
        iconAnchor: IconAnchor.BOTTOM,
        textField: v['name'],
        textSize: 14.0,
        textOffset: [0.0, 0.5],
        textColor: Colors.black.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 3.0,
      );
    }).toList();

    if (options.isNotEmpty) {
      await pointAnnotationManager!.createMulti(options);
      if (_filteredVenues.isNotEmpty && mapboxMap != null) {
        mapboxMap!.flyTo(
            CameraOptions(center: Point(coordinates: Position((_filteredVenues[0]['lng'] ?? 0).toDouble(), (_filteredVenues[0]['lat'] ?? 0).toDouble())), zoom: 13.5, pitch: 45.0),
            MapAnimationOptions(duration: 1200));
      }
    }
  }

  void _mostrarTarjetaCancha(Map<String, dynamic> venue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Center(child: Icon(Icons.location_on, color: Colors.red, size: 35))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                        const SizedBox(height: 6),
                        Text('${venue['sport']} • Zona ${venue['zone']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () { Navigator.pop(context); Navigator.pop(context, venue); },
                  child: const Text('Confirmar esta Cancha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(key: const ValueKey("mapboxMap_fullscreen"), styleUri: MapboxStyles.MAPBOX_STREETS, onMapCreated: _onMapCreated),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  FloatingActionButton(heroTag: "backBtn", mini: true, backgroundColor: Colors.white, child: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50, padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                      child: TextField(
                        controller: searchController,
                        onChanged: (val) { setState(() => _searchQuery = val); _updateMapMarkers(); },
                        decoration: const InputDecoration(icon: Icon(Icons.search, color: Colors.green), hintText: 'Buscar cancha por nombre...', border: InputBorder.none),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30)),
                child: const Text("Toca un marcador 📍 para elegir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          )
        ],
      ),
    );
  }
}