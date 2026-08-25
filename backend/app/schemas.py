from __future__ import annotations

from typing import Literal
from uuid import UUID

from pydantic import BaseModel

PlacaKind = Literal["publicacion", "busqueda"]
PlacaFormat = Literal["feed", "story"]


class ConsumeRequest(BaseModel):
    request_id: UUID
    template_id: str
    kind: PlacaKind
    formats: list[PlacaFormat]
    include_contact: bool


class ConsumeResponse(BaseModel):
    granted: bool
    reason: str
    used: int
    quota_limit: int | None
    remaining: int | None


class BillingStatus(BaseModel):
    tier: Literal["free", "pro"]
    status: Literal["none", "pending", "authorized", "paused", "cancelled", "courtesy"]
    current_period_end: str | None = None


class SubscribeRequest(BaseModel):
    payer_email: str


class SubscribeResponse(BaseModel):
    preapproval_id: str
    init_point: str
