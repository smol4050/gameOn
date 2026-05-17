import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'confirmar_unirse_screen.dart'; // 🔹 Navegación para unirse a eventos
import 'crear_evento_screen.dart'; // 🔹 Importamos la nueva pantalla

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _canCreateEvents = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // 🔹 LÓGICA DE ROLES: Verifica si es admin o creador de eventos
  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final role = doc.data()!['role'] ?? 'user';

        setState(() {
          // Los dos pueden crear eventos
          _canCreateEvents = (role == 'admin' || role == 'creador_eventos');
          // SOLO el admin es admin
          _isAdmin = (role == 'admin');
        });
      }
    } catch (e) {
      debugPrint("Error verificando rol: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 🔹 Tenemos 2 pestañas: "Próximos" y "En Curso"
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        
        // 🔥 BOTÓN FLOTANTE: Solo aparece si _canCreateEvents es true
        floatingActionButton: _canCreateEvents
            ? FloatingActionButton.extended(
                onPressed: () {
                  // 🔹 NAVEGAMOS A LA PANTALLA DE CREAR EVENTO
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrearEventoScreen(isAdmin: _isAdmin),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF155DFC),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Crear Evento', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              )
            : null,

        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 HEADER Y TABS
              Container(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eventos',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF155DFC),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Torneos y competencias oficiales',
                              style: TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            size: 28,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 🔹 TAB BAR (Controlador de pestañas)
                    const TabBar(
                      indicatorColor: Color(0xFF155DFC),
                      labelColor: Color(0xFF155DFC),
                      unselectedLabelColor: Color(0xFF6A7282),
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      tabs: [
                        Tab(text: "Próximos"),
                        Tab(text: "En Curso"),
                      ],
                    ),
                  ],
                ),
              ),

              // 🔹 CONTENIDO DE LAS PESTAÑAS (Firestore Stream)
              Expanded(
                child: TabBarView(
                  children: [
                    _buildEventsList(status: 'upcoming'), // Pestaña 1
                    _buildEventsList(status: 'ongoing'),  // Pestaña 2
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 LISTA EN TIEMPO REAL DESDE FIRESTORE
  Widget _buildEventsList({required String status}) {
    return StreamBuilder<QuerySnapshot>(
      // Filtramos por el campo "status" en Firestore
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              status == 'upcoming' 
                  ? 'No hay eventos próximos aún.' 
                  : 'No hay eventos en curso.',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
            ),
          );
        }

        final events = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 24, bottom: 120),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final doc = events[index];
            final eventData = doc.data() as Map<String, dynamic>;
            final eventId = doc.id;

            // 🔹 Renderizado Inteligente: Si en BD le pusiste "isFeatured: true", lo hace grande
            if (eventData['isFeatured'] == true) {
              return Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 28),
                child: _featuredEvent(context, eventData, eventId),
              );
            }

            // Diseño normal de lista
            return _eventCard(
              context, 
              eventData, 
              eventId,
              ongoing: status == 'ongoing'
            );
          },
        );
      },
    );
  }

  // 🔥 EVENTO DESTACADO (Adaptado a Firestore)
  Widget _featuredEvent(BuildContext context, Map<String, dynamic> featuredData, String eventId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(blurRadius: 18, offset: Offset(0, 6), color: Colors.black12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Image.network(
                  featuredData['image'] ?? 'https://via.placeholder.com/400',
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: 240,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF6900),
                      borderRadius: BorderRadius.circular(50)),
                  child: const Text(
                    'DESTACADO',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 22,
                child: Text(
                  featuredData['title'] ?? 'Evento',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _infoRow(Icons.calendar_today_outlined, featuredData['date'] ?? 'Por definir'),
                const SizedBox(height: 14),
                _infoRow(Icons.location_on_outlined, featuredData['location'] ?? 'Ubicación'),
                const SizedBox(height: 28),

                // 🔹 BUTTON DESTACADO
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF155DFC), Color(0xFF2E7D32)]),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ConfirmarUnirseScreen(
                                    matchId: eventId,
                                    matchData: featuredData)));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent),
                      child: const Text(
                        'Inscribirse Ahora',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 EVENT CARD (Adaptada a Firestore)
  Widget _eventCard(BuildContext context, Map<String, dynamic> event, String eventId, {bool ongoing = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(blurRadius: 10, offset: Offset(0, 3), color: Colors.black12)
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    event['image'] ?? 'https://via.placeholder.com/100',
                    width: 100, 
                    height: 100, 
                    fit: BoxFit.cover
                  ),
                ),
                if (ongoing)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFF6900),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('EN CURSO',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title'] ?? 'Torneo',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 8),
                  _miniInfo(Icons.attach_money, event['price'] ?? 'Gratis', orange: true),
                  const SizedBox(height: 4),
                  _miniInfo(Icons.location_on_outlined, event['location'] ?? 'Ubicación'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ConfirmarUnirseScreen(
                                    matchId: eventId,
                                    matchData: event)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Ver más',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white), 
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF155DFC), size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Color(0xFF4A5565), fontSize: 15)),
      ],
    );
  }

  Widget _miniInfo(IconData icon, String text, {bool orange = false}) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color: orange ? const Color(0xFFF54900) : const Color(0xFF6A7282)),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color: orange ? const Color(0xFFF54900) : const Color(0xFF4A5565),
                fontSize: 12)),
      ],
    );
  }
}