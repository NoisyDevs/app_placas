"""Tests del cliente HTTP real de Mercado Pago contra un transport simulado."""

import json

import httpx

from app.config import Settings
from app.services.mercadopago import HttpMercadoPagoClient


def _capturing_transport(captured: list[httpx.Request]) -> httpx.MockTransport:
    def handler(request: httpx.Request) -> httpx.Response:
        captured.append(request)
        return httpx.Response(
            201,
            json={
                "id": "pre-123",
                "status": "pending",
                "init_point": "https://mp.test/checkout",
                "external_reference": "user-1",
            },
        )

    return httpx.MockTransport(handler)


async def _create(settings: Settings) -> dict:
    captured: list[httpx.Request] = []
    client = HttpMercadoPagoClient(settings, transport=_capturing_transport(captured))
    try:
        await client.create_preapproval(
            payer_email="agente@example.com",
            external_reference="user-1",
            reason="Suscripcion Pro",
            back_url="https://example.com/back",
        )
    finally:
        await client.aclose()
    assert len(captured) == 1
    assert captured[0].url.path == "/preapproval"
    return json.loads(captured[0].content)


async def test_create_preapproval_sends_default_monthly_amount():
    body = await _create(Settings())

    auto_recurring = body["auto_recurring"]
    assert auto_recurring["transaction_amount"] == 8500.0
    assert auto_recurring["currency_id"] == "ARS"
    assert auto_recurring["frequency"] == 1
    assert auto_recurring["frequency_type"] == "months"


async def test_create_preapproval_respects_custom_amount():
    body = await _create(Settings(mercadopago_monthly_amount_ars=12345.5))

    assert body["auto_recurring"]["transaction_amount"] == 12345.5
