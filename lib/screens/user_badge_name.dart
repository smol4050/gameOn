import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      mainAxisSize:
          MainAxisSize.min, // Para que se ajuste al texto y no rompa el diseño
      children: [
        Flexible(
          child: Text(
            name,
            style: textStyle ??
                TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 🔹 MEDALLITA DE ADMIN
        if (role == 'admin') ...[
          SizedBox(width: 4.w),
          Icon(Icons.verified, color: AppColors.primary, size: iconSize.r),
        ]
        // 🔹 MEDALLITA DE CREADOR DE EVENTOS
        else if (role == 'creador') ...[
          SizedBox(width: 4.w),
          Icon(Icons.local_police, color: AppColors.warning, size: iconSize.r),
        ],
      ],
    );
  }
}
