"""Verificación de la firma del webhook de Mercado Pago.

Esquema documentado por MP: el header `x-signature` trae `ts=...,v1=...`; el
manifest a firmar es `id:{data_id};request-id:{x_request_id};ts:{ts};`
(HMAC-SHA256 con el webhook secret, en hex). MP no envía siempre las mismas
partes para todos los topics — reconciliar contra una entrega real antes de
salir a producción (ver ARCHITECTURE.md §6).
"""

from __future__ import annotations

import hashlib
import hmac


def _parse_signature_header(header_value: str) -> dict[str, str]:
    parts: dict[str, str] = {}
    for chunk in header_value.split(","):
        if "=" not in chunk:
            continue
        key, _, value = chunk.partition("=")
        parts[key.strip()] = value.strip()
    return parts


def build_manifest(*, data_id: str, request_id: str, ts: str) -> str:
    return f"id:{data_id};request-id:{request_id};ts:{ts};"


def verify_mp_signature(
    *, x_signature: str, x_request_id: str, data_id: str, secret: str
) -> bool:
    parts = _parse_signature_header(x_signature)
    ts = parts.get("ts")
    v1 = parts.get("v1")
    if not ts or not v1:
        return False

    manifest = build_manifest(data_id=data_id, request_id=x_request_id, ts=ts)
    expected = hmac.new(secret.encode(), manifest.encode(), hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, v1)
