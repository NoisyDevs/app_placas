from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import get_settings
from app.routers import billing, placas, webhooks
from app.services.mercadopago import HttpMercadoPagoClient
from app.supabase import SupabaseClient


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    app.state.supabase = SupabaseClient(settings)
    app.state.mp_client = HttpMercadoPagoClient(settings)
    try:
        yield
    finally:
        await app.state.supabase.aclose()
        await app.state.mp_client.aclose()


app = FastAPI(title="Generador de Placas — backend", lifespan=lifespan)

app.include_router(placas.router)
app.include_router(billing.router)
app.include_router(webhooks.router)


@app.get("/v1/health")
async def health() -> dict:
    return {"status": "ok"}
