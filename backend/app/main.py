from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

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

# El cliente Flutter web y este backend nunca comparten origen (puertos
# distintos en dev, dominios distintos en producción), así que el browser
# exige CORS para cualquier llamada con Authorization/JSON — sin esto,
# TODAS las llamadas desde `services/backend_client.dart` fallan en el
# preflight antes de llegar a un router. `allow_origins=["*"]` porque no
# hay cookies de sesión (el JWT va en el header Authorization, no en una
# cookie), así que no hay riesgo de CSRF vía credentials. No toca ningún
# router ni la lógica de negocio testeada — puramente aditivo.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(placas.router)
app.include_router(billing.router)
app.include_router(webhooks.router)


@app.get("/v1/health")
async def health() -> dict:
    return {"status": "ok"}
