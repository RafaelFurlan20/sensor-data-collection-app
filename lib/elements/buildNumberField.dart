import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:explorer/constants.dart';

Padding buildNumberField({
  required Function(String?) function,
  required String hText,
  bool enabled = true,
  IconData? prefixIcon,
  String? initialValue,
  bool allowDecimal = true,
  bool allowNegative = false,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(
      vertical: kPadding / 2,
      horizontal: kPadding,
    ),
    child: TextField(
      enabled: enabled,
      controller: initialValue != null ? TextEditingController(text: initialValue) : null,
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
          vertical: 12,
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(
        decimal: allowDecimal,
        signed: allowNegative,
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(
          RegExp(allowNegative
              ? r'^-?\d*[.,]?\d*$'
              : r'^\d*[.,]?\d*$'
          ),
        ),
      ],
      onChanged: (value) {
        function(value);
      },
    ),
  );
}