"""Máquina de estados (tier, status) de la suscripción. Ver ARCHITECTURE.md §6.

Regla dura #1: una fila 'courtesy' nunca se toca acá. El webhook la salta
antes de siquiera llamar a esta función.

Regla dura #2: esta función nunca decide el estado a partir del payload del
webhook — recibe el estado ya re-consultado a la API de MP (fuente de
verdad), así una entrega fuera de orden es inofensiva.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from app.services.mercadopago import MpPreapprovalStatus

PlanTier = str  # 'free' | 'pro'
SubStatus = str  # 'none' | 'pending' | 'authorized' | 'paused' | 'cancelled' | 'courtesy'

# Mapeo de estado de MP -> (tier, status) local. Es la única fuente de verdad
# de la transición; si un estado de MP no está acá, es una transición
# ilegal/desconocida y se rechaza en vez de aplicarse a ciegas.
#
# 'cancelled' y 'paused' mapean a tier='pro', NO a 'free': quota_status() en
# supabase/schema.sql decide "sigue con acceso pago" mirando primero
# `tier = 'pro'` y recién después si `current_period_end` ya venció. Si acá
# bajáramos tier a 'free' de una, el downgrade perezoso hasta fin de período
# (lo que promete Historia 3.2: "si vence/cancelo, vuelvo a las condiciones
# del free") se rompe y el agente pierde el acceso pago que ya pagó.
_MP_STATUS_TO_LOCAL: dict[MpPreapprovalStatus, tuple[PlanTier, SubStatus]] = {
    "pending": ("free", "pending"),      # nunca estuvo autorizado: no hay período pago que cuidar
    "authorized": ("pro", "authorized"),
    "paused": ("pro", "paused"),
    "cancelled": ("pro", "cancelled"),
}


class CourtesyAccountError(RuntimeError):
    """Se intentó aplicar una transición de MP sobre una cuenta courtesy."""


class UnknownMercadoPagoStatusError(RuntimeError):
    def __init__(self, status: str):
        super().__init__(f"Estado de Mercado Pago desconocido: {status!r}")
        self.status = status


@dataclass(frozen=True)
class SubscriptionPatch:
    tier: PlanTier
    status: SubStatus
    current_period_end: datetime | None


def apply_mp_status(
    *,
    current_status: SubStatus,
    mp_status: str,
    previous_period_end: datetime | None = None,
    authorized_period_length: timedelta = timedelta(days=31),
) -> SubscriptionPatch:
    """Calcula el patch a aplicar a `subscriptions` dado el estado real en MP.

    `previous_period_end` es el `current_period_end` que la suscripción ya
    tenía guardado ANTES de este webhook — el caller lo lee de la fila actual
    y lo pasa acá. Solo se usa para 'paused'/'cancelled', para preservar la
    gracia hasta que venza el período que el agente ya pagó. Para
    'authorized' NUNCA se reutiliza ese valor: sería una fecha vieja, no la
    del ciclo que se acaba de cobrar. La fecha real de próximo cobro no viene
    en el objeto de preapproval que consultamos hoy, así que se aproxima con
    `authorized_period_length` (1 mes) desde el momento del webhook.
    """
    if current_status == "courtesy":
        raise CourtesyAccountError(
            "cuenta courtesy: las transiciones de Mercado Pago no se aplican"
        )

    if mp_status not in _MP_STATUS_TO_LOCAL:
        raise UnknownMercadoPagoStatusError(mp_status)

    tier, status = _MP_STATUS_TO_LOCAL[mp_status]

    if status == "authorized":
        period_end = datetime.now(timezone.utc) + authorized_period_length
    elif status in ("paused", "cancelled"):
        # Sigue "pro" hasta que venza el período ya pagado (downgrade
        # perezoso, ver quota_status() en supabase/schema.sql).
        period_end = previous_period_end
    else:
        period_end = None

    return SubscriptionPatch(tier=tier, status=status, current_period_end=period_end)
