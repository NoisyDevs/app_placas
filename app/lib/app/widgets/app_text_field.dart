import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Input neutro con label flotante fijo arriba (como el mockup) y contador
/// opcional de caracteres — primera capa de defensa contra overflow de
/// texto en placas (ver ARCHITECTURE.md §2, "Se ataja en el input").
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.hint,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final counterLabel = maxLength == null ? label : '$label (máx. $maxLength)';
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: maxLength == null ? null : [LengthLimitingTextInputFormatter(maxLength)],
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: counterLabel,
        hintText: hint,
        counterText: maxLength == null ? '' : null,
      ),
    );
  }
}
