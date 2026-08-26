import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base URL de `backend/` (FastAPI) — ver ARCHITECTURE.md §6. Overrideable
/// con `--dart-define=BACKEND_BASE_URL=...` para apuntar a un ambiente
/// desplegado; en dev local es el uvicorn que corre en la máquina.
const String _defaultBackendBaseUrl = 'http://localhost:8000';

/// Error genérico de una llamada al backend: red caída, 401/404/500, etc.
/// ARCHITECTURE.md §5.6: "Backend inalcanzable → falla cerrado, con mensaje
/// claro y reintento. Nunca falla abierto" — por eso esto SIEMPRE se lanza
/// (nunca se traga un error para simular éxito).
class BackendException implements Exception {
  BackendException(this.statusCode, this.message, {this.code});

  /// 0 cuando ni siquiera hubo respuesta HTTP (red caída / backend abajo).
  final int statusCode;
  final String message;
  final String? code;

  @override
  String toString() => 'BackendException($statusCode${code != null ? ', $code' : ''}): $message';
}

/// 403 `quota_exceeded` de `POST /v1/placas/consume` — ver ARCHITECTURE.md
/// §5.3. Se modela aparte del resto de `BackendException` porque no es una
/// falla: es una respuesta de negocio válida que la UI debe manejar
/// redirigiendo a `/upgrade`, no mostrando un error genérico.
class QuotaExceededException extends BackendException {
  QuotaExceededException({required this.used, required this.quotaLimit})
      : super(403, 'Ya usaste todo tu cupo de placas de este mes', code: 'quota_exceeded');

  final int used;
  final int? quotaLimit;
}

class ConsumeResult {
  const ConsumeResult({required this.granted, required this.reason, required this.used, required this.quotaLimit, this.remaining});

  final bool granted;

  /// 'granted' (primera vez) o 'replay' (mismo `request_id` reenviado —
  /// idempotente, no cobra de nuevo). Ver `consume_placa_credit()` en
  /// supabase/schema.sql.
  final String reason;
  final int used;

  /// null == cupo ilimitado (plan pro vigente).
  final int? quotaLimit;
  final int? remaining;
}

class BillingStatusResult {
  const BillingStatusResult({required this.tier, required this.status, this.currentPeriodEnd});

  final String tier; // 'free' | 'pro'
  final String status; // 'none' | 'pending' | 'authorized' | 'paused' | 'cancelled' | 'courtesy'
  final String? currentPeriodEnd;
}

class SubscribeResult {
  const SubscribeResult({required this.preapprovalId, required this.initPoint});

  final String preapprovalId;

  /// URL de checkout de Mercado Pago a la que hay que llevar al agente para
  /// completar el pago. La suscripción queda en `(free, pending)` hasta que
  /// el webhook confirme la autorización — ver ARCHITECTURE.md §6.
  final String initPoint;
}

/// Cliente HTTP delgado hacia `backend/`. Solo sabe adjuntar el JWT de la
/// sesión activa de Supabase (`Authorization: Bearer ...`) y traducir
/// respuestas HTTP a los tipos de arriba — no sabe nada de `AgentProfile`
/// ni de cómo se autenticó el agente (eso es responsabilidad de
/// `features/auth/`).
class BackendClient {
  BackendClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? const String.fromEnvironment('BACKEND_BASE_URL', defaultValue: _defaultBackendBaseUrl);

  final http.Client _http;
  final String _baseUrl;

  Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ConsumeResult> consumePlacaCredit({
    required String requestId,
    required String templateId,
    required String kind,
    required List<String> formats,
    required bool includeContact,
  }) async {
    final response = await _send(() => _http.post(
          Uri.parse('$_baseUrl/v1/placas/consume'),
          headers: _headers,
          body: jsonEncode({
            'request_id': requestId,
            'template_id': templateId,
            'kind': kind,
            'formats': formats,
            'include_contact': includeContact,
          }),
        ));

    final body = _decodeBody(response);

    if (response.statusCode == 403) {
      final detail = body?['detail'];
      final detailMap = detail is Map ? detail : const {};
      throw QuotaExceededException(
        used: (detailMap['used'] as num?)?.toInt() ?? 0,
        quotaLimit: (detailMap['quota_limit'] as num?)?.toInt(),
      );
    }
    _throwIfError(response, body);

    return ConsumeResult(
      granted: body?['granted'] as bool? ?? false,
      reason: body?['reason'] as String? ?? 'granted',
      used: (body?['used'] as num?)?.toInt() ?? 0,
      quotaLimit: (body?['quota_limit'] as num?)?.toInt(),
      remaining: (body?['remaining'] as num?)?.toInt(),
    );
  }

  Future<BillingStatusResult> getBillingStatus() async {
    final response = await _send(() => _http.get(Uri.parse('$_baseUrl/v1/billing/status'), headers: _headers));
    final body = _decodeBody(response);
    _throwIfError(response, body);
    return BillingStatusResult(
      tier: body?['tier'] as String? ?? 'free',
      status: body?['status'] as String? ?? 'none',
      currentPeriodEnd: body?['current_period_end'] as String?,
    );
  }

  Future<SubscribeResult> subscribe({required String payerEmail}) async {
    final response = await _send(() => _http.post(
          Uri.parse('$_baseUrl/v1/billing/subscribe'),
          headers: _headers,
          body: jsonEncode({'payer_email': payerEmail}),
        ));
    final body = _decodeBody(response);
    _throwIfError(response, body);
    return SubscribeResult(
      preapprovalId: body?['preapproval_id'] as String? ?? '',
      initPoint: body?['init_point'] as String? ?? '',
    );
  }

  Future<void> cancelSubscription() async {
    final response = await _send(() => _http.post(Uri.parse('$_baseUrl/v1/billing/cancel'), headers: _headers));
    if (response.statusCode == 204) return;
    _throwIfError(response, _decodeBody(response));
  }

  /// Envuelve la llamada de red: si el backend está inalcanzable (servidor
  /// caído, sin conexión), esto lanza `BackendException(0, ...)` en vez de
  /// dejar escapar la excepción cruda de `http` — ARCHITECTURE.md §5.6,
  /// "falla cerrado, con mensaje claro".
  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on BackendException {
      rethrow;
    } catch (_) {
      throw BackendException(0, 'No pudimos conectar con el servidor. Revisá tu conexión e intentá de nuevo.', code: 'network_error');
    }
  }

  void _throwIfError(http.Response response, Map<String, dynamic>? body) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw BackendException(response.statusCode, _errorMessage(body), code: _errorCode(body));
  }

  Map<String, dynamic>? _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _errorMessage(Map<String, dynamic>? body) {
    final detail = body?['detail'];
    if (detail is String) return detail;
    if (detail is Map) return detail['code']?.toString() ?? detail.toString();
    return 'No pudimos completar la operación. Intentá de nuevo en unos minutos.';
  }

  String? _errorCode(Map<String, dynamic>? body) {
    final detail = body?['detail'];
    if (detail is Map) return detail['code']?.toString();
    return null;
  }
}

/// Una sola instancia por sesión de la app — no guarda estado propio más
/// allá del `http.Client` interno, así que no hace falta recrearla.
final backendClientProvider = Provider<BackendClient>((ref) => BackendClient());
