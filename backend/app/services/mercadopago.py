"""Cliente de Mercado Pago Suscripciones (preapproval).

Se define como Protocol para que los routers dependan de la interfaz, no de
la implementación HTTP real — así los tests corren sin credenciales de MP
(ver tests/conftest.py, que inyecta un FakeMercadoPagoClient).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal, Protocol

import httpx

from app.config import Settings

MpPreapprovalStatus = Literal["pending", "authorized", "paused", "cancelled"]


@dataclass(frozen=True)
class PreapprovalResult:
    preapproval_id: str
    status: MpPreapprovalStatus
    init_point: str | None = None
    external_reference: str | None = None


class MercadoPagoClient(Protocol):
    async def create_preapproval(
        self, *, payer_email: str, external_reference: str, reason: str, back_url: str
    ) -> PreapprovalResult: ...

    async def get_preapproval(self, preapproval_id: str) -> PreapprovalResult: ...

    async def cancel_preapproval(self, preapproval_id: str) -> PreapprovalResult: ...


class HttpMercadoPagoClient:
    """Implementación real, contra la API pública de Mercado Pago."""

    _BASE_URL = "https://api.mercadopago.com"

    def __init__(self, settings: Settings, *, transport: httpx.AsyncBaseTransport | None = None):
        self._monthly_amount_ars = settings.mercadopago_monthly_amount_ars
        self._client = httpx.AsyncClient(
            base_url=self._BASE_URL,
            headers={"Authorization": f"Bearer {settings.mercadopago_access_token}"},
            transport=transport,
            timeout=15.0,
        )

    async def aclose(self) -> None:
        await self._client.aclose()

    async def create_preapproval(
        self, *, payer_email: str, external_reference: str, reason: str, back_url: str
    ) -> PreapprovalResult:
        response = await self._client.post(
            "/preapproval",
            json={
                "reason": reason,
                "external_reference": external_reference,
                "payer_email": payer_email,
                "back_url": back_url,
                "auto_recurring": {
                    "frequency": 1,
                    "frequency_type": "months",
                    "currency_id": "ARS",
                    # El monto sale de Settings. En ARS queda fijo al crear la
                    # suscripción — ver ARCHITECTURE.md §9 (punto 5) sobre la
                    # actualización trimestral del precio.
                    "transaction_amount": self._monthly_amount_ars,
                },
                "status": "pending",
            },
        )
        response.raise_for_status()
        body = response.json()
        return PreapprovalResult(
            preapproval_id=body["id"],
            status=body["status"],
            init_point=body.get("init_point"),
            external_reference=body.get("external_reference"),
        )

    async def get_preapproval(self, preapproval_id: str) -> PreapprovalResult:
        response = await self._client.get(f"/preapproval/{preapproval_id}")
        response.raise_for_status()
        body = response.json()
        return PreapprovalResult(
            preapproval_id=body["id"],
            status=body["status"],
            external_reference=body.get("external_reference"),
        )

    async def cancel_preapproval(self, preapproval_id: str) -> PreapprovalResult:
        response = await self._client.put(
            f"/preapproval/{preapproval_id}", json={"status": "cancelled"}
        )
        response.raise_for_status()
        body = response.json()
        return PreapprovalResult(preapproval_id=body["id"], status=body["status"])
