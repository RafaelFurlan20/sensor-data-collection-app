import 'package:flutter/material.dart';
import 'package:explorer/constants.dart';

Padding buildTextField({
  required Function(String) function,
  required String hText,
  TextInputType? keyboardType,
  bool obscureText = false,
  IconData? prefixIcon,
  String? initialValue,
  int? maxLines = 1,
  bool enabled = true,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(
      vertical: kPadding / 2,
      horizontal: kPadding,
    ),
    child: TextField(
      enabled: enabled,
      controller: initialValue != null ? TextEditingController(text: initialValue) : null,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        // Consistent border styling
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white,
            width: 2.0,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1.0,
          ),
        ),

        // Background and fill
        filled: true,
        fillColor: enabled
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),

        // Hint styling
        hintText: hText,
        hintStyle: TextStyle(
          color: enabled
              ? Colors.white54
              : Colors.white24,
          fontSize: 14,
        ),

        // Optional prefix icon
        prefixIcon: prefixIcon != null
            ? Icon(
          prefixIcon,
          color: enabled
              ? Colors.white
              : Colors.white24,
        )
            : null,

        // Content padding
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefixIcon != null ? 12 : 16,
          vertical: maxLines! > 1 ? 16 : 12,
        ),
      ),
      onChanged: (value) {
        function(value);
      },
    ),
  );
}