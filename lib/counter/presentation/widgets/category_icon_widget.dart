import 'package:flutter/material.dart';
import 'package:wallet/counter/domain/category_icons.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    required this.iconCode,
    this.colorCode,
    this.size,
    super.key,
  });

  final int iconCode;
  final int? colorCode;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      iconDataForCode(iconCode),
      size: size,
      color: colorCode != null ? Color(colorCode!) : null,
    );
  }
}
