from __future__ import annotations

import logging
from datetime import datetime

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status

from app.config import Settings, get_settings
from app.deps import get_mp_client, get_supabase
from app.services.billing_state import CourtesyAccountError, apply_mp_status
from app.services.mercadopago import MercadoPagoClient
from app.services.mp_signature import verify_mp_signature
from app.supabase import SupabaseClient

router = APIRouter(prefix="/v1/webhooks", tags=["webhooks"])
logger = logging.getLogger(__name__)


@router.post("/mercadopago", status_code=status.HTTP_200_OK)
async def mercadopago_webhook(
    request: Request,
    x_signature: str = Header(default=""),
    x_request_id: str = Header(default=""),
    settings: Settings = Depends(get_settings),
    supabase: SupabaseClient = Depends(get_supabase),
    mp_client: MercadoPagoClient = Depends(get_mp_client),
) -> dict:
    body = await request.json()
    data_id = str(body.get("data", {}).get("id") or "")

    if not verify_mp_signature(
        x_signature=x_signature,
        x_request_id=x_request_id,
        data_id=data_id,
        secret=settings.mercadopago_webhook_secret,
    ):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Firma inválida")

    mp_event_id = f"{data_id}:{x_request_id}"
    is_new = await supabase.insert_ignore_conflict(
        "mp_webhook_events",
        row={"mp_event_id": mp_event_id, "topic": body.get("type", ""), "payload": body},
        on_conflict="mp_event_id",
    )
    if not is_new:
        # Ya procesado en una entrega anterior. MP reintenta ante cualquier
        # respuesta que no sea 2xx, así que esto tiene que devolver 200.
        return {"status": "already_processed"}

    # Nunca se confía en el payload del webhook — ni para el estado ni para
    # el external_reference (el payload real de MP solo trae `data.id`, no
    # el resto de los campos de la preapproval). Se re-consulta a MP, que es
    # la fuente de verdad. Así una entrega fuera de orden (ej. "paused"
    # llega después de "authorized") también es inofensiva.
    preapproval = await mp_client.get_preapproval(data_id)

    agent_id = preapproval.external_reference
    if not agent_id:
        logger.warning("Preapproval de MP sin external_reference: %s", data_id)
        return {"status": "missing_external_reference"}

    subscription = await supabase.select_one("subscriptions", agent_id=agent_id)
    if subscription is None:
        logger.warning("Webhook de MP para agente desconocido: %s", agent_id)
        return {"status": "unknown_agent"}

    raw_period_end = subscription.get("current_period_end")
    previous_period_end = datetime.fromisoformat(raw_period_end) if raw_period_end else None

    try:
        patch = apply_mp_status(
            current_status=subscription["status"],
            mp_status=preapproval.status,
            previous_period_end=previous_period_end,
        )
    except CourtesyAccountError:
        logger.info("Webhook de MP ignorado: cuenta courtesy (%s)", agent_id)
        return {"status": "ignored_courtesy_account"}

    await supabase.update_one(
        "subscriptions",
        agent_id=agent_id,
        patch={
            "tier": patch.tier,
            "status": patch.status,
            "current_period_end": patch.current_period_end.isoformat()
            if patch.current_period_end
            else None,
        },
    )

    return {"status": "applied"}
