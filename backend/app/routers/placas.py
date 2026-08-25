from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.deps import get_supabase, require_agent_id
from app.schemas import ConsumeRequest, ConsumeResponse
from app.supabase import SupabaseClient

router = APIRouter(prefix="/v1/placas", tags=["placas"])


@router.post("/consume", response_model=ConsumeResponse)
async def consume_placa_credit(
    body: ConsumeRequest,
    agent_id: str = Depends(require_agent_id),
    supabase: SupabaseClient = Depends(get_supabase),
) -> ConsumeResponse:
    """Consume un crédito de placa. No genera la imagen — eso ocurre en el
    dispositivo. Ver ARCHITECTURE.md §5: el servidor vende permiso, no
    píxeles."""
    rows = await supabase.rpc(
        "consume_placa_credit",
        {
            "p_agent": agent_id,
            "p_request": str(body.request_id),
            "p_template": body.template_id,
            "p_kind": body.kind,
            "p_formats": body.formats,
            "p_include_contact": body.include_contact,
        },
    )
    row = rows[0]
    quota_limit = row["quota_limit"]
    used = row["used"]
    remaining = None if quota_limit is None else max(quota_limit - used, 0)

    if not row["granted"]:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            detail={
                "code": row["reason"],
                "used": used,
                "quota_limit": quota_limit,
            },
        )

    return ConsumeResponse(
        granted=True,
        reason=row["reason"],
        used=used,
        quota_limit=quota_limit,
        remaining=remaining,
    )
