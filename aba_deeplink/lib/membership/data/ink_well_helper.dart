import 'package:flutter/material.dart';

Widget createInkWell({
  required Widget child,
  VoidCallback? onTap,
  bool disabled = false,
  Color backgroundColor = Colors.white,
  Color? splashColor,
  BorderRadius? borderRadius,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: disabled ? null : onTap,
      child: child,
      borderRadius: borderRadius,
      splashColor: splashColor ?? Colors.grey,
    ),
  );
}
