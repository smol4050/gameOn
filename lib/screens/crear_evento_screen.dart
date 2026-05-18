import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide ImageSource;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../services/image_service.dart'; // 🔹 Asegúrate de que esta ruta sea correcta

class CrearEventoScreen extends StatefulWidget {
  final bool isAdmin; // Para saber si puede destacar

  const CrearEventoScreen({super.key, required this.isAdmin});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int players = 32; // Por defecto más grande para eventos
  int price = 2000;
  bool _isLoading = false;
  bool _isLoadingVenues = true;

  String? _selectedSport;
  String? _selectedLocation;
  String? _selectedZone;
  final String _searchQuery = "";

  // 🔹 CAMPOS ESPECÍFICOS DE EVENTOS
  String _status = 'upcoming'; 
  bool _isFeatured = false;

  // 🔹 VARIABLES PARA IMAGEN
  String? _eventImageUrl;
  bool _isUploadingImage = false;

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

  // 🔹 LÓGICA MÁGICA DE CANCHAS
  Future<void> _fetchCanchasDesdeFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('canchas').get();

      if (snapshot.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _venues = snapshot.docs.map((doc) => doc.data()).toList();
          _isLoadingVenues = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingVenues = false);
      }

      if (pointAnnotationManager != null) {
        _updateMapMarkers();
      }
    } catch (e) {
      debugPrint("Error al cargar canchas: $e");
      if (mounted) setState(() => _isLoadingVenues = false);
    }
  }

  // 🔹 LÓGICA DE SUBIDA DE IMAGEN
  Future<void> _pickAndUploadEventImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          "${tempDir.path}/event_${DateTime.now().millisecondsSinceEpoch}.jpg";

      // Comprimimos la imagen
      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 60, 
        minWidth: 800,
        minHeight: 600,
      );

      if (compressedFile != null) {
        final String? url = await ImageService.uploadImage(
          File(compressedFile.path),
        );

        if (url != null) {
          if (mounted) setState(() => _eventImageUrl = url);
        }
      }
    } catch (e) {
      debugPrint("Error subiendo imagen del evento: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir la imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // 🚀 FUNCIÓN PARA ABRIR PANTALLA COMPLETA
  void _abrirMapaCompleto() async {
    final selectedVenue = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapaPantallaCompletaEventoScreen(
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
            center: Point(
                coordinates: Position(
                    selectedVenue['lng'] as num, selectedVenue['lat'] as num)),
            zoom: 14.5,
            pitch: 45.0,
          ),
          MapAnimationOptions(duration: 1500));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      nameController.text.isNotEmpty &&
      selectedDate != null &&
      selectedTime != null &&
      _selectedSport != null &&
      _selectedLocation != null;

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
      final searchMatch = venue['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      return sportMatch && zoneMatch && searchMatch;
    }).toList();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    mapboxMap.setCamera(CameraOptions(
        center: Point(coordinates: Position(-76.5227, 3.3536)),
        zoom: 13.5,
        pitch: 45.0,
        bearing: -17.0));

    mapboxMap.loadStyleURI(MapboxStyles.MAPBOX_STREETS).then((_) {
      _add3DBuildings();
      mapboxMap.annotations.createPointAnnotationManager().then((manager) {
        pointAnnotationManager = manager;
        pointAnnotationManager!.tapEvents(onTap:(annotation) {
          final lat = annotation.geometry.coordinates.lat;
          final lng = annotation.geometry.coordinates.lng;

          final clickedVenue = _venues.firstWhere(
            (v) => v['lat'] == lat && v['lng'] == lng,
            orElse: () => <String, dynamic>{},
          );
          if (clickedVenue.isEmpty) return;

          setState(() => _selectedLocation = clickedVenue['name']);

          mapboxMap.flyTo(
              CameraOptions(
                  center: Point(coordinates: Position(lng, lat)),
                  zoom: 16.5,
                  pitch: 60.0),
              MapAnimationOptions(duration: 1500));
        });

        if (!_isLoadingVenues) _updateMapMarkers();
      });
    });
  }

  Future<void> _add3DBuildings() async {
    try {
      await mapboxMap?.style.addLayer(FillExtrusionLayer(
        id: "3d-buildings",
        sourceId: "composite",
        sourceLayer: "building",
        minZoom: 15.0,
        filter: ["==", "extrude", "true"],
        fillExtrusionColor: Colors.grey.toARGB32(),
        fillExtrusionOpacity: 0.6,
        fillExtrusionHeight: 30.0,
        fillExtrusionBase: 0.0,
      ));
    } catch (e) {
      debugPrint("Error al cargar capa 3D: $e");
    }
  }

  void _updateMapMarkers() async {
    if (pointAnnotationManager == null) return;
    await pointAnnotationManager!.deleteAll();

    List<PointAnnotationOptions> options = _filteredVenues.map((v) {
      return PointAnnotationOptions(
        geometry: Point(coordinates: Position(v['lng'] as num, v['lat'] as num)),
        iconImage: "marker-15",
        iconSize: 1.8,
        textField: v['name'],
        textSize: 13.0,
        textOffset: [0.0, 1.2],
        textColor: Colors.black.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 2.0,
      );
    }).toList();

    if (options.isNotEmpty) {
      await pointAnnotationManager!.createMulti(options);
      if (_filteredVenues.isNotEmpty) {
        mapboxMap?.flyTo(
            CameraOptions(
                center: Point(
                    coordinates: Position(_filteredVenues[0]['lng'] as num,
                        _filteredVenues[0]['lat'] as num)),
                zoom: 13.5,
                pitch: 45.0),
            MapAnimationOptions(duration: 1200));
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030));
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _crearEvento() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);

    try {
      final dateString = "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} - ${selectedTime!.format(context)}";

      final eventData = {
        'title': nameController.text.trim(),
        'sport': _selectedSport,
        'location': _selectedLocation,
        'date': dateString, 
        'price': '\$$price COP',
        // 🔹 Si hay URL subida la usa, si no, usa la default
        'image': _eventImageUrl ?? 'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?q=80&w=1200&auto=format&fit=crop',
        'status': _status,
        'isFeatured': _isFeatured,
        'joinedSlots': 0,
        'totalSlots': players,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('events').add(eventData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Evento publicado exitosamente'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Regresa a la lista de eventos
    } catch (e) {
      debugPrint("Error al crear evento: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Crear Evento',
            style: TextStyle(
                color: Color(0xFF111827), fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: _isLoadingVenues
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF155DFC)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Nombre del Evento'),
                  const SizedBox(height: 8),
                  _input(nameController, 'Ej. Torneo de Verano'),

                  const SizedBox(height: 24),
                  _label('Imagen del Evento (Opcional)'),
                  const SizedBox(height: 8),
                  _buildImageUploader(), // 🔹 NUEVO WIDGET AQUÍ

                  const SizedBox(height: 24),
                  _label('Selecciona el Deporte'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        'Fútbol', 'Baloncesto', 'Tenis', 'Ultimate', 'Vóley'
                      ].map((sport) {
                        final emojis = {
                          'Fútbol': '⚽', 'Baloncesto': '🏀', 'Tenis': '🎾',
                          'Ultimate': '🥏', 'Vóley': '🏐'
                        };
                        final colors = {
                          'Fútbol': Colors.green, 'Baloncesto': Colors.orange,
                          'Tenis': Colors.red, 'Ultimate': Colors.blue,
                          'Vóley': Colors.deepPurple
                        };
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSport = sport;
                              _selectedLocation = null;
                            });
                            _updateMapMarkers();
                          },
                          child: _SportCard(
                              title: sport,
                              emoji: emojis[sport]!,
                              color: colors[sport]!,
                              isSelected: _selectedSport == sport),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Lugar del Evento'),
                      if (_selectedLocation != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFF155DFC).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(_selectedLocation!,
                              style: const TextStyle(
                                  color: Color(0xFF155DFC),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Norte', 'Sur', 'Centro', 'Oriente', 'Occidente'
                      ].map((zone) {
                        final isSelected = _selectedZone == zone;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(zone,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87)),
                            selected: isSelected,
                            selectedColor: const Color(0xFF155DFC),
                            backgroundColor: Colors.white,
                            onSelected: (selected) {
                              setState(
                                  () => _selectedZone = selected ? zone : null);
                              _updateMapMarkers();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🔹 MAPA PEQUEÑO (Con textureView activado)
                  GestureDetector(
                    onTap: _abrirMapaCompleto,
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 15)
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          AbsorbPointer(
                            child: MapWidget(
                              key: const ValueKey("mapboxMapEvent_small"),
                              textureView: true, 
                              styleUri: MapboxStyles.MAPBOX_STREETS,
                              onMapCreated: (MapboxMap map) {
                                _onMapCreated(map);
                                map.compass.updateSettings(
                                    CompassSettings(enabled: false));
                                map.scaleBar.updateSettings(
                                    ScaleBarSettings(enabled: false));
                              },
                            ),
                          ),
                          Positioned(
                            top: 15, left: 15, right: 15,
                            child: Container(
                              height: 45,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black26, blurRadius: 10)
                                  ]),
                              child: const Row(
                                children: [
                                  Icon(Icons.search, color: Color(0xFF155DFC)),
                                  SizedBox(width: 10),
                                  Text(
                                      'Toca para buscar en pantalla completa...',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10, right: 10,
                            child: FloatingActionButton.small(
                              heroTag: "expandBtnEvent",
                              backgroundColor: Colors.black87,
                              onPressed: _abrirMapaCompleto,
                              child: const Icon(Icons.fullscreen,
                                  color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _dateBox(
                              title: 'Fecha',
                              value: selectedDate == null
                                  ? 'Seleccionar'
                                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                              icon: Icons.calendar_today,
                              onTap: _selectDate)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _dateBox(
                              title: 'Hora',
                              value: selectedTime == null
                                  ? 'Seleccionar'
                                  : selectedTime!.format(context),
                              icon: Icons.access_time,
                              onTap: _selectTime)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _label('Cupos de Jugadores'),
                  _counterBox(),

                  const SizedBox(height: 24),
                  _label('Precio de Inscripción'),
                  _priceBox(),

                  const SizedBox(height: 32),

                  _label('Estado del Evento'),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                            value: 'upcoming',
                            label: Text('Próximo', style: TextStyle(fontSize: 14))),
                        ButtonSegment<String>(
                            value: 'ongoing',
                            label: Text('En Curso', style: TextStyle(fontSize: 14))),
                      ],
                      selected: {_status},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => _status = newSelection.first);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF155DFC).withValues(alpha: 0.15);
                            }
                            return Colors.white;
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: SwitchListTile(
                      title: const Text("Destacar Evento", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(widget.isAdmin 
                        ? "Aparecerá gigante en la pantalla." 
                        : "Solo los administradores pueden destacar."),
                      value: _isFeatured,
                      activeThumbColor: const Color(0xFFFF6900),
                      activeTrackColor: const Color(0xFFFF6900).withValues(alpha: 0.3),
                      secondary: Icon(
                        Icons.star, 
                        color: widget.isAdmin ? const Color(0xFFFF6900) : Colors.grey
                      ),
                      onChanged: widget.isAdmin 
                        ? (bool value) => setState(() => _isFeatured = value)
                        : null,
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // --- WIDGETS DE APOYO ---

  // 🔹 WIDGET DE IMAGEN INTEGRADO
  Widget _buildImageUploader() {
    return GestureDetector(
      onTap: _isUploadingImage ? null : _pickAndUploadEventImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
          image: _eventImageUrl != null
              ? DecorationImage(
                  image: NetworkImage(_eventImageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _isUploadingImage
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF155DFC)),
              )
            : _eventImageUrl == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 50,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Añadir foto del evento (Opcional)",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: SizedBox(
        height: 58,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF155DFC), // Color de Eventos
            disabledBackgroundColor: Colors.grey.shade300,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: (_isLoading || !_isFormValid) ? null : _crearEvento,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _isFormValid
                      ? 'PUBLICAR EVENTO'
                      : 'COMPLETE TODOS LOS CAMPOS',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF364153))));

  Widget _input(TextEditingController controller, String hint) => Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(14)),
        child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
                border: InputBorder.none, hintText: hint)),
      );

  Widget _dateBox(
          {required String title,
          required String value,
          required IconData icon,
          required VoidCallback onTap}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(title),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(icon, size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600))
              ]),
            ),
          ),
        ],
      );

  Widget _counterBox() => Container(
        height: 70,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _circleBtn(
              Icons.remove,
              () => setState(() {
                    players--;
                    if (players < 1) players = 1;
                  })),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text('$players',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold))),
          _circleBtn(Icons.add, () => setState(() => players++)),
        ]),
      );

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
              color: Color(0xFF155DFC), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20)));

  Widget _priceBox() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(14)),
        child: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 28,
              color: Color(0xFF155DFC),
              fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
              prefixText: '\$ ', suffixText: ' COP', border: InputBorder.none),
          onChanged: (v) => price = int.tryParse(v) ?? 0,
        ),
      );
}

class _SportCard extends StatelessWidget {
  final String title, emoji;
  final Color color;
  final bool isSelected;
  const _SportCard(
      {required this.title,
      required this.emoji,
      required this.color,
      required this.isSelected});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isSelected ? color : Colors.white,
        border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB), width: 2),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87)),
      ]),
    );
  }
}



// =========================================================
// 🌍 PANTALLA DE MAPA COMPLETO
// =========================================================
class MapaPantallaCompletaEventoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> venues;
  final String? selectedSport;
  final String? selectedZone;

  const MapaPantallaCompletaEventoScreen(
      {super.key, required this.venues, this.selectedSport, this.selectedZone});

  @override
  State<MapaPantallaCompletaEventoScreen> createState() =>
      _MapaPantallaCompletaEventoScreenState();
}

class _MapaPantallaCompletaEventoScreenState
    extends State<MapaPantallaCompletaEventoScreen> {
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
      bool sportMatch = widget.selectedSport == null ||
          (widget.selectedSport == 'Ultimate'
              ? (venue['sport'] == 'Ultimate' || venue['sport'] == 'Fútbol')
              : venue['sport'] == widget.selectedSport);
      bool zoneMatch =
          widget.selectedZone == null || venue['zone'] == widget.selectedZone;
      bool searchMatch = venue['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return sportMatch && zoneMatch && searchMatch;
    }).toList();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;

    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    mapboxMap.setCamera(CameraOptions(
        center: Point(coordinates: Position(-76.5227, 3.3536)),
        zoom: 13.0,
        pitch: 45.0));

    mapboxMap.loadStyleURI(MapboxStyles.MAPBOX_STREETS).then((_) {
      mapboxMap.style.addLayer(FillExtrusionLayer(
        id: "3d-buildings",
        sourceId: "composite",
        sourceLayer: "building",
        minZoom: 15.0,
        filter: ["==", "extrude", "true"],
        fillExtrusionColor: Colors.grey.toARGB32(),
        fillExtrusionOpacity: 0.6,
        fillExtrusionHeight: 30.0,
        fillExtrusionBase: 0.0,
      ));

      mapboxMap.annotations.createPointAnnotationManager().then((manager) {
        pointAnnotationManager = manager;
        pointAnnotationManager!.tapEvents(onTap:(annotation) {
          final lat = annotation.geometry.coordinates.lat;
          final lng = annotation.geometry.coordinates.lng;
          final clickedVenue = widget.venues.firstWhere(
            (v) => v['lat'] == lat && v['lng'] == lng,
            orElse: () => <String, dynamic>{},
          );
          if (clickedVenue.isEmpty) return;

          Navigator.pop(context, clickedVenue);
        });
        _updateMapMarkers();
      });
    });
  }

  void _updateMapMarkers() async {
    if (pointAnnotationManager == null) return;
    await pointAnnotationManager!.deleteAll();

    List<PointAnnotationOptions> options = _filteredVenues.map((v) {
      return PointAnnotationOptions(
        geometry:
            Point(coordinates: Position(v['lng'] as num, v['lat'] as num)),
        iconImage: "marker-15",
        iconSize: 0.8,
        textField: v['name'],
        textSize: 13.0,
        textOffset: [0.0, 1.2],
        textColor: Colors.black.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 2.0,
      );
    }).toList();

    if (options.isNotEmpty) {
      await pointAnnotationManager!.createMulti(options);
      if (_filteredVenues.isNotEmpty) {
        mapboxMap?.flyTo(
            CameraOptions(
                center: Point(
                    coordinates: Position(_filteredVenues[0]['lng'] as num,
                        _filteredVenues[0]['lat'] as num)),
                zoom: 13.5,
                pitch: 45.0),
            MapAnimationOptions(duration: 1200));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
              key: const ValueKey("mapboxMapEvent_fullscreen"),
              textureView: true, 
              styleUri: MapboxStyles.MAPBOX_STREETS,
              onMapCreated: _onMapCreated),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  FloatingActionButton(
                    heroTag: "backBtnEvent",
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10)
                          ]),
                      child: TextField(
                        controller: searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                          _updateMapMarkers();
                        },
                        decoration: const InputDecoration(
                            icon: Icon(Icons.search, color: Color(0xFF155DFC)),
                            hintText: 'Buscar lugar por nombre...',
                            border: InputBorder.none),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30)),
                child: const Text("Toca un marcador 📍 para elegir",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
          )
        ],
      ),
    );
  }
}