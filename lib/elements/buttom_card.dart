import 'package:flutter/material.dart';

class ButtomCard extends StatelessWidget {
  final String text;
  final VoidCallback function;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final bool enabled;

  const ButtomCard({
    Key? key,
    required this.text,
    required this.function,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: enabled ? (_) { function(); } : null,
      child: Card(
        color: enabled
            ? (backgroundColor ?? Colors.white.withOpacity(0.15))
            : Colors.grey.withOpacity(0.1),
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: enabled
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        elevation: enabled ? 2 : 0,
        child: ListTile(
          leading: Icon(
            icon,
            size: 20,
            color: enabled
                ? (iconColor ?? Colors.white)
                : Colors.white.withOpacity(0.3),
          ),
          title: Text(
            text,
            style: TextStyle(
              color: enabled
                  ? (textColor ?? Colors.white)
                  : Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: enabled
              ? Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.5),
          )
              : null,
        ),
      ),
    );
  }
}