import 'package:flutter/widgets.dart';

import '../../domain/placa_render_model.dart';

/// Bloque de contacto: avatar (iniciales) + nombre + WhatsApp + matrícula,
/// o — cuando `contact` es `null` (Historia 2.6: contacto apagado) —
/// solamente la línea de matrícula centrada, si el template la requiere.
/// La regla legal "la matrícula sobrevive aunque el contacto esté oculto"
/// no puede olvidarse acá porque `contact` y `matricula` llegan como
/// campos independientes desde `PlacaRenderModel` (ver ARCHITECTURE.md §2,
/// regla 2) — este widget no decide esa regla, solo la dibuja.
class ContactStrip extends StatelessWidget {
  const ContactStrip({
    super.key,
    required this.contact,
    required this.matricula,
    required this.avatarColor,
    required this.avatarTextColor,
    required this.avatarRadius,
    required this.nameStyle,
    required this.whatsappStyle,
    required this.matriculaStyle,
    this.matriculaAlign = TextAlign.right,
  });

  final ContactBlock? contact;
  final String? matricula;
  final Color avatarColor;
  final Color avatarTextColor;
  final double avatarRadius;
  final TextStyle nameStyle;
  final TextStyle whatsappStyle;
  final TextStyle matriculaStyle;
  final TextAlign matriculaAlign;

  static String initialsOf(String nombre) {
    final parts = nombre.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    return parts.take(2).map((s) => s[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final contact = this.contact;
    final matricula = this.matricula;

    if (contact == null) {
      if (matricula == null) return const SizedBox.shrink();
      return Text(
        '$matricula · consultá con tu agente',
        style: matriculaStyle,
        textAlign: TextAlign.center,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: avatarRadius * 2,
          height: avatarRadius * 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
          child: Text(initialsOf(contact.nombre), style: TextStyle(color: avatarTextColor, fontWeight: FontWeight.w800)),
        ),
        SizedBox(width: avatarRadius * 0.55),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(contact.nombre, style: nameStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(contact.whatsapp, style: whatsappStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (matricula != null) ...[
          SizedBox(width: avatarRadius * 0.4),
          Text(matricula, style: matriculaStyle, textAlign: matriculaAlign),
        ],
      ],
    );
  }
}
