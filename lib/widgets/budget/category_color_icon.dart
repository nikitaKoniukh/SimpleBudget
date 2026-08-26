import 'package:flutter/material.dart';

import '../../data/category_icons.dart';

/// Colored circle with a category icon inside.
class CategoryColorIcon extends StatelessWidget {
  const CategoryColorIcon({
    super.key,
    required this.colorValue,
    required this.iconKey,
    this.size = 32,
  });

  final int colorValue;
  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bg = Color(colorValue);
    final iconColor =
        bg.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        iconDataForKey(iconKey),
        size: size * 0.55,
        color: iconColor,
      ),
    );
  }
}
