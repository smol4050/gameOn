import 'package:flutter/material.dart';

class UserBadgeName extends StatelessWidget {
  final String name;
  final String? role;
  final TextStyle? textStyle;
  final double iconSize;

  const UserBadgeName({
    super.key,
    required this.name,
    this.role,
    this.textStyle,
    this.iconSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Para que se ajuste al texto y no rompa el diseño
      children: [
        Flexible(
          child: Text(
            name,
            style: textStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 🔹 MEDALLITA DE ADMIN
        if (role == 'admin') ...[
          const SizedBox(width: 4),
          Icon(Icons.verified, color: Colors.blueAccent, size: iconSize), 
        ] 
        // 🔹 MEDALLITA DE CREADOR DE EVENTOS
        else if (role == 'creador') ...[
          const SizedBox(width: 4),
          Icon(Icons.local_police, color: Colors.amber, size: iconSize), 
        ],
      ],
    );
  }
}