from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.deps import get_mp_client, get_supabase, require_agent_id
from app.schemas import BillingStatus, SubscribeRequest, SubscribeResponse
from app.services.mercadopago import MercadoPagoClient
from app.supabase import SupabaseClient

router = APIRouter(prefix="/v1/billing", tags=["billing"])


@router.get("/status", response_model=BillingStatus)
async def billing_status(
    agent_id: str = Depends(require_agent_id),
    supabase: SupabaseClient = Depends(get_supabase),
) -> BillingStatus:
    row = await supabase.select_one("subscriptions", agent_id=agent_id)
    if row is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No existe suscripción para este agente")
    return BillingStatus(
        tier=row["tier"],
        status=row["status"],
        current_period_end=row.get("current_period_end"),
    )


@router.post("/subscribe", response_model=SubscribeResponse)
async def subscribe(
    body: SubscribeRequest,
    agent_id: str = Depends(require_agent_id),
    supabase: SupabaseClient = Depends(get_supabase),
    mp_client: MercadoPagoClient = Depends(get_mp_client),
) -> SubscribeResponse:
    """Crea la preapproval en Mercado Pago y deja la suscripción en
    (free, pending) hasta que el webhook confirme la autorización."""
    row = await supabase.select_one("subscriptions", agent_id=agent_id)
    if row is not None and row["status"] == "courtesy":
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Esta cuenta ya tiene Pro de cortesía"
        )

    result = await mp_client.create_preapproval(
        payer_email=body.payer_email,
        external_reference=agent_id,
        reason="Generador de Placas RE/MAX — plan Pro",
        back_url="https://placas.remax.example/plan/gracias",
    )

    await supabase.update_one(
        "subscriptions",
        agent_id=agent_id,
        patch={"status": "pending", "mp_preapproval_id": result.preapproval_id},
    )

    return SubscribeResponse(
        preapproval_id=result.preapproval_id,
        init_point=result.init_point or "",
    )


@router.post("/cancel", status_code=status.HTTP_204_NO_CONTENT)
async def cancel(
    agent_id: str = Depends(require_agent_id),
    supabase: SupabaseClient = Depends(get_supabase),
    mp_client: MercadoPagoClient = Depends(get_mp_client),
) -> None:
    row = await supabase.select_one("subscriptions", agent_id=agent_id)
    if row is None or row["status"] == "courtesy":
        raise HTTPException(status.HTTP_409_CONFLICT, "No hay suscripción de Mercado Pago para cancelar")

    preapproval_id = row.get("mp_preapproval_id")
    if not preapproval_id:
        raise HTTPException(status.HTTP_409_CONFLICT, "La suscripción no tiene preapproval activa")

    await mp_client.cancel_preapproval(preapproval_id)
    # El estado local definitivo lo aplica el webhook al re-consultar MP;
    # acá solo se dispara la cancelación. No hay estado "cancelling"
    # intermedio: la máquina de estados solo conoce los que reconoce MP.
