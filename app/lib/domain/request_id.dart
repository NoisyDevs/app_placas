import 'dart:math';

/// Genera un UUID v4 para `client_request_id` (ver ARCHITECTURE.md §5.3 y
/// §4 "Idempotencia": `placa_events` tiene `unique (agent_id,
/// client_request_id)`, así que reintentar el mismo id nunca cobra dos
/// veces). Dart puro, sin dependencias — no hace falta el paquete `uuid`
/// solo para esto.
String generateRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // versión 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC 4122

  String hex(int start, int end) => bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
