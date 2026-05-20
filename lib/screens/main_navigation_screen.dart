import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'home_screen.dart';
import 'eventos_screen.dart';
import 'agenda_screen.dart';
import 'perfil_screen.dart';
import 'crear_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 3).toInt();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const EventsScreen(),
    const AgendaScreen(),
    const PerfilScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final navHeight = (screenHeight * 0.075).clamp(58.0, 72.0);
    final fabSize = (screenWidth * 0.14).clamp(52.0, 64.0);

    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: SizedBox(
        width: fabSize.w,
        height: fabSize.h,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CrearScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: Icon(Icons.add, color: Colors.white, size: (fabSize * 0.48).r),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: screenWidth * 0.02,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: navHeight.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Expanded(
                        child: _navItem(Icons.home, 'Inicio', 0, screenWidth)),
                    Expanded(
                        child:
                            _navItem(Icons.explore, 'Eventos', 1, screenWidth)),
                  ],
                ),
              ),
              SizedBox(width: (fabSize * 1.05).w),
              Flexible(
                child: Row(
                  children: [
                    Expanded(
                        child: _navItem(
                            Icons.calendar_today, 'Agenda', 2, screenWidth)),
                    Expanded(
                        child:
                            _navItem(Icons.person, 'Perfil', 3, screenWidth)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, double screenWidth) {
    final isActive = _selectedIndex == index;
    return MaterialButton(
      padding: EdgeInsets.zero,
      minWidth: screenWidth * 0.12,
      onPressed: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: (screenWidth * 0.055).clamp(20.0, 26.0).r,
            color: isActive ? AppColors.primary : Colors.grey,
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: (screenWidth * 0.03).clamp(10.0, 12.5).sp,
              color: isActive ? AppColors.primary : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
