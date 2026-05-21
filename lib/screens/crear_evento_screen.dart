import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../constants/app_sports.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide ImageSource;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../services/image_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CrearEventoScreen extends StatefulWidget {
  final bool isAdmin;

  const CrearEventoScreen({super.key, required this.isAdmin});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int players = 32;
  int price = 2000;
  bool _isLoading = false;
  bool _isLoadingVenues = true;

  String? _selectedSport;
  String? _selectedLocation;
  String? _selectedZone;
  final String _searchQuery = "";

  String _status = 'upcoming';
  bool _isFeatured = false;

  String? _eventImageUrl;
  bool _isUploadingImage = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController =
      TextEditingController(text: '2000');

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
      final snapshot =
          await FirebaseFirestore.instance.collection('canchas').get();

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

  Future<void> _pickAndUploadEventImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          "${tempDir.path}/event_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 60,
        minWidth: 800,
        minHeight: 600,
      );

      if (compressedFile != null) {
        final String? url =
            await ImageService.uploadImage(File(compressedFile.path));
        if (url != null) {
          if (mounted) setState(() => _eventImageUrl = url);
        }
      }
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

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
      setState(() => _selectedLocation = selectedVenue['name']);
      mapboxMap?.flyTo(
          CameraOptions(
              center: Point(
                  coordinates: Position(selectedVenue['lng'] as num,
                      selectedVenue['lat'] as num)),
              zoom: 14.5,
              pitch: 45.0),
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
      final sportMatch =
          _selectedSport == null || venue['sport'] == _selectedSport;
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
        pointAnnotationManager!.tapEvents(onTap: (annotation) {
          final lat = annotation.geometry.coordinates.lat;
          final lng = annotation.geometry.coordinates.lng;
          final clickedVenue = _venues.firstWhere(
              (v) => v['lat'] == lat && v['lng'] == lng,
              orElse: () => <String, dynamic>{});
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
        fillExtrusionColor: AppColors.textSecondary.toARGB32(),
        fillExtrusionOpacity: 0.6,
        fillExtrusionHeight: 30.0,
        fillExtrusionBase: 0.0,
      ));
    } catch (e) {
      debugPrint("Error al cargar capa 3D: $e");
    }
  }

  // 🔹 GENERADOR DE PIN EN MEMORIA
  Future<Uint8List> _crearPinRojo() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    double size = 90.0;
    final TextPainter textPainter =
        TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.location_on.codePoint),
      style: TextStyle(
          fontSize: size.sp,
          fontFamily: Icons.location_on.fontFamily,
          color: AppColors.error),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0.0, 0.0));
    final ui.Image image = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _updateMapMarkers() async {
    if (pointAnnotationManager == null) return;
    await pointAnnotationManager!.deleteAll();

    final Uint8List pinImage = await _crearPinRojo();

    List<PointAnnotationOptions> options = _filteredVenues.map((v) {
      return PointAnnotationOptions(
        geometry: Point(
            coordinates: Position(
                (v['lng'] ?? 0).toDouble(), (v['lat'] ?? 0).toDouble())),
        image: pinImage,
        iconSize: 0.8,
        iconAnchor: IconAnchor.BOTTOM,
        textField: v['name'],
        textSize: 14.0,
        textOffset: [0.0, 0.5],
        textColor: AppColors.textSecondary.toARGB32(),
        textHaloColor: AppColors.textLight.toARGB32(),
        textHaloWidth: 3.0,
      );
    }).toList();

    if (options.isNotEmpty) {
      await pointAnnotationManager!.createMulti(options);
      if (_filteredVenues.isNotEmpty && mapboxMap != null) {
        mapboxMap!.flyTo(
            CameraOptions(
                center: Point(
                    coordinates: Position(
                        (_filteredVenues[0]['lng'] ?? 0).toDouble(),
                        (_filteredVenues[0]['lat'] ?? 0).toDouble())),
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
        lastDate: DateTime(2030),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: AppColors.textLight,
                onSurface: AppColors.textSecondary,
              ),
            ),
            child: child!,
          );
        });
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: AppColors.textLight,
                onSurface: AppColors.textSecondary,
              ),
            ),
            child: child!,
          );
        });
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _crearEvento() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);

    try {
      final dateString =
          "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} - ${selectedTime!.format(context)}";
      final eventData = {
        'title': nameController.text.trim(),
        'sport': _selectedSport,
        'location': _selectedLocation,
        'date': dateString,
        'price': '\$$price COP',
        'image': _eventImageUrl ??
            'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?q=80&w=1200&auto=format&fit=crop',
        'status': _status,
        'isFeatured': _isFeatured,
        'joinedSlots': 0,
        'totalSlots': players,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('events').add(eventData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Evento publicado exitosamente'),
          backgroundColor: AppColors.primary));
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error al crear evento: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al crear: $e'),
          backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.textLight,
        elevation: 0,
        title: const Text('Crear Evento',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoadingVenues
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Nombre del Evento'),
                  SizedBox(height: 8.h),
                  _input(nameController, 'Ej. Torneo de Verano'),
                  SizedBox(height: 24.h),
                  _label('Imagen del Evento (Opcional)'),
                  SizedBox(height: 8.h),
                  _buildImageUploader(),
                  SizedBox(height: 24.h),
                  _label('Selecciona el Deporte'),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 120.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: AppSports.values.map((sport) {
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
                              emoji: AppSports.emojiFor(sport),
                              color: AppSports.colorFor(sport),
                              isSelected: _selectedSport == sport),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Lugar del Evento'),
                      if (_selectedLocation != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.r, vertical: 4.r),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r)),
                          child: Text(_selectedLocation!,
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Norte',
                        'Sur',
                        'Centro',
                        'Oriente',
                        'Occidente'
                      ].map((zone) {
                        final isSelected = _selectedZone == zone;
                        return Padding(
                          padding: EdgeInsets.only(right: 8.r),
                          child: ChoiceChip(
                            label: Text(zone,
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isSelected
                                        ? AppColors.textLight
                                        : AppColors.textSecondary)),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.textLight,
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
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: _abrirMapaCompleto,
                    child: Container(
                      height: 250.h,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.border, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.1),
                                blurRadius: 15)
                          ]),
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
                            top: 15,
                            left: 15,
                            right: 15,
                            child: Container(
                              height: 45.h,
                              padding: EdgeInsets.symmetric(horizontal: 16.r),
                              decoration: BoxDecoration(
                                  color: AppColors.textLight,
                                  borderRadius: BorderRadius.circular(30.r),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: AppColors.softOverlay,
                                        blurRadius: 10)
                                  ]),
                              child: Row(children: [
                                const Icon(Icons.search,
                                    color: AppColors.primary),
                                SizedBox(width: 10.w),
                                Text('Toca para buscar en pantalla completa...',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13.sp))
                              ]),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: FloatingActionButton.small(
                                heroTag: "expandBtnEvent",
                                backgroundColor: AppColors.textSecondary,
                                onPressed: _abrirMapaCompleto,
                                child: const Icon(Icons.fullscreen,
                                    color: AppColors.textLight)),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
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
                      SizedBox(width: 16.w),
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
                  SizedBox(height: 24.h),
                  _label('Cupos de Jugadores'),
                  _counterBox(),
                  SizedBox(height: 24.h),
                  _label('Precio de Inscripción'),
                  _priceBox(),
                  SizedBox(height: 32.h),
                  _label('Estado del Evento'),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                            value: 'upcoming',
                            label: Text('Próximo',
                                style: TextStyle(fontSize: 14.sp))),
                        ButtonSegment<String>(
                            value: 'ongoing',
                            label: Text('En Curso',
                                style: TextStyle(fontSize: 14.sp))),
                      ],
                      selected: {_status},
                      onSelectionChanged: (Set<String> newSelection) =>
                          setState(() => _status = newSelection.first),
                      style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) =>
                                      states.contains(WidgetState.selected)
                                          ? AppColors.primary
                                              .withValues(alpha: 0.15)
                                          : AppColors.textLight)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    decoration: BoxDecoration(
                        color: AppColors.textLight,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.border)),
                    child: SwitchListTile(
                      title: const Text("Destacar Evento",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(widget.isAdmin
                          ? "Aparecerá gigante en la pantalla."
                          : "Solo los administradores pueden destacar."),
                      value: _isFeatured,
                      activeThumbColor: AppColors.warning,
                      activeTrackColor:
                          AppColors.warning.withValues(alpha: 0.3),
                      secondary: Icon(Icons.star,
                          color: widget.isAdmin
                              ? AppColors.warning
                              : AppColors.textSecondary),
                      onChanged: widget.isAdmin
                          ? (bool value) => setState(() => _isFeatured = value)
                          : null,
                    ),
                  ),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildImageUploader() {
    return GestureDetector(
      onTap: _isUploadingImage ? null : _pickAndUploadEventImage,
      child: Container(
        height: 200.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.textLight,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border, width: 2),
          image: _eventImageUrl != null
              ? DecorationImage(
                  image: NetworkImage(_eventImageUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: _isUploadingImage
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _eventImageUrl == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 50.r, color: AppColors.border),
                      SizedBox(height: 10.h),
                      const Text("Añadir foto del evento (Opcional)",
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600))
                    ],
                  )
                : Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                        padding: EdgeInsets.all(12.0.r),
                        child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: const BoxDecoration(
                                color: AppColors.overlay,
                                shape: BoxShape.circle),
                            child: Icon(Icons.edit,
                                color: AppColors.textLight, size: 20.r)))),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: const BoxDecoration(
          color: AppColors.textLight,
          border: Border(top: BorderSide(color: AppColors.border))),
      child: SizedBox(
        height: 58.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.disabled,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r))),
          onPressed: (_isLoading || !_isFormValid) ? null : _crearEvento,
          child: _isLoading
              ? const CircularProgressIndicator(color: AppColors.textLight)
              : Text(
                  _isFormValid
                      ? 'PUBLICAR EVENTO'
                      : 'COMPLETE TODOS LOS CAMPOS',
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textLight)),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
      padding: EdgeInsets.only(bottom: 8.r),
      child: Text(text,
          style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary)));

  Widget _input(TextEditingController controller, String hint) => Container(
        height: 54.h,
        padding: EdgeInsets.symmetric(horizontal: 16.r),
        decoration: BoxDecoration(
            color: AppColors.textLight,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14.r)),
        child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration:
                InputDecoration(border: InputBorder.none, hintText: hint)),
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
              height: 54.h,
              padding: EdgeInsets.symmetric(horizontal: 16.r),
              decoration: BoxDecoration(
                  color: AppColors.textLight,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14.r)),
              child: Row(children: [
                Icon(icon, size: 18.r, color: AppColors.textSecondary),
                SizedBox(width: 12.w),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600))
              ]),
            ),
          ),
        ],
      );

  Widget _counterBox() => Container(
        height: 70.h,
        decoration: BoxDecoration(
            color: AppColors.textLight,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14.r)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _circleBtn(
              Icons.remove,
              () => setState(() {
                    players--;
                    if (players < 1) players = 1;
                  })),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.r),
              child: Text('$players',
                  style:
                      TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold))),
          _circleBtn(Icons.add, () => setState(() => players++)),
        ]),
      );

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 40.w,
          height: 40.h,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.textLight, size: 20.r)));

  Widget _priceBox() => Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
            color: AppColors.textLight,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14.r)),
        child: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 28.sp,
              color: AppColors.primary,
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
      width: 100.w,
      margin: EdgeInsets.only(right: 12.r),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: isSelected ? color : AppColors.textLight,
          border: Border.all(
              color: isSelected ? color : AppColors.border, width: 2)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: TextStyle(fontSize: 28.sp)),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? AppColors.textLight : AppColors.textSecondary))
      ]),
    );
  }
}

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
      final sportMatch = widget.selectedSport == null ||
          venue['sport'] == widget.selectedSport;
      final zoneMatch =
          widget.selectedZone == null || venue['zone'] == widget.selectedZone;
      final searchMatch = venue['name']
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
        fillExtrusionColor: AppColors.textSecondary.toARGB32(),
        fillExtrusionOpacity: 0.6,
        fillExtrusionHeight: 30.0,
        fillExtrusionBase: 0.0,
      ));

      mapboxMap.annotations.createPointAnnotationManager().then((manager) {
        pointAnnotationManager = manager;
        pointAnnotationManager!.tapEvents(onTap: (annotation) {
          final lat = annotation.geometry.coordinates.lat;
          final lng = annotation.geometry.coordinates.lng;
          final clickedVenue = widget.venues.firstWhere(
              (v) => v['lat'] == lat && v['lng'] == lng,
              orElse: () => <String, dynamic>{});
          if (clickedVenue.isEmpty) return;

          // Hacemos vuelo y abrimos tarjeta
          mapboxMap.flyTo(
              CameraOptions(
                  center: Point(coordinates: Position(lng, lat)),
                  zoom: 16.5,
                  pitch: 60.0),
              MapAnimationOptions(duration: 1200));
          _mostrarTarjetaCancha(clickedVenue);
        });
        _updateMapMarkers();
      });
    });
  }

  Future<Uint8List> _crearPinRojo() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    double size = 90.0;
    final TextPainter textPainter =
        TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.location_on.codePoint),
      style: TextStyle(
          fontSize: size.sp,
          fontFamily: Icons.location_on.fontFamily,
          color: AppColors.error),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0.0, 0.0));
    final ui.Image image = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _updateMapMarkers() async {
    if (pointAnnotationManager == null) return;
    await pointAnnotationManager!.deleteAll();

    final Uint8List pinImage = await _crearPinRojo();

    List<PointAnnotationOptions> options = _filteredVenues.map((v) {
      return PointAnnotationOptions(
        geometry: Point(
            coordinates: Position(
                (v['lng'] ?? 0).toDouble(), (v['lat'] ?? 0).toDouble())),
        image: pinImage,
        iconSize: 0.8,
        iconAnchor: IconAnchor.BOTTOM,
        textField: v['name'],
        textSize: 14.0,
        textOffset: [0.0, 0.5],
        textColor: AppColors.textSecondary.toARGB32(),
        textHaloColor: AppColors.textLight.toARGB32(),
        textHaloWidth: 3.0,
      );
    }).toList();

    if (options.isNotEmpty) {
      await pointAnnotationManager!.createMulti(options);
      if (_filteredVenues.isNotEmpty && mapboxMap != null) {
        mapboxMap!.flyTo(
            CameraOptions(
                center: Point(
                    coordinates: Position(
                        (_filteredVenues[0]['lng'] ?? 0).toDouble(),
                        (_filteredVenues[0]['lat'] ?? 0).toDouble())),
                zoom: 13.5,
                pitch: 45.0),
            MapAnimationOptions(duration: 1200));
      }
    }
  }

  void _mostrarTarjetaCancha(Map<String, dynamic> venue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.r),
          decoration: const BoxDecoration(
              color: AppColors.textLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      height: 60.h,
                      width: 60.w,
                      decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: Center(
                          child: Icon(Icons.location_on,
                              color: AppColors.error, size: 35.r))),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue['name'],
                            style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 6.h),
                        Text('${venue['sport']} • Zona ${venue['zone']}',
                            style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r))),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, venue);
                  },
                  child: Text('Confirmar esta Cancha',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textLight)),
                ),
              ),
              SizedBox(height: 10.h),
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
          MapWidget(
              key: const ValueKey("mapboxMapEvent_fullscreen"),
              textureView: true,
              styleUri: MapboxStyles.MAPBOX_STREETS,
              onMapCreated: _onMapCreated),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0.r),
              child: Row(
                children: [
                  FloatingActionButton(
                      heroTag: "backBtnEvent",
                      mini: true,
                      backgroundColor: AppColors.textLight,
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Container(
                      height: 50.h,
                      padding: EdgeInsets.symmetric(horizontal: 16.r),
                      decoration: BoxDecoration(
                          color: AppColors.textLight,
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: const [
                            BoxShadow(
                                color: AppColors.softOverlay, blurRadius: 10)
                          ]),
                      child: TextField(
                        controller: searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                          _updateMapMarkers();
                        },
                        decoration: const InputDecoration(
                            icon: Icon(Icons.search, color: AppColors.primary),
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
                padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 12.r),
                decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(30.r)),
                child: Text("Toca un marcador 📍 para elegir",
                    style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
