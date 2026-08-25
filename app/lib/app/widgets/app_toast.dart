import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Toast flotante simple, equivalente al `toast(msg)` del mockup
/// ("Placa descargada · lista para publicar").
void showAppToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 24,
      right: 24,
      bottom: 32,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(12)),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textInverse, fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2200), () {
    entry.remove();
  });
}
