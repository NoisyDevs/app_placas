"""Verificación del JWT de Supabase Auth.

`agent_id` (el `sub` del token) es la única identidad que el backend conoce.
Nunca se confía en un agent_id que venga en el body de un request: siempre
sale del token verificado.
"""

from __future__ import annotations

from functools import lru_cache

import jwt
from fastapi import Header, HTTPException, Request, status
from jwt import PyJWKClient

from app.config import get_settings
from app.services.mercadopago import MercadoPagoClient
from app.supabase import SupabaseClient

_AUDIENCE = "authenticated"


@lru_cache
def _jwk_client(jwks_url: str) -> PyJWKClient:
    return PyJWKClient(jwks_url, cache_keys=True)


def _decode_with_jwks(token: str) -> dict:
    settings = get_settings()
    client = _jwk_client(settings.supabase_jwks_url)
    signing_key = client.get_signing_key_from_jwt(token)
    return jwt.decode(
        token,
        signing_key.key,
        algorithms=["RS256", "ES256"],
        audience=_AUDIENCE,
    )


def _decode_with_shared_secret(token: str) -> dict:
    settings = get_settings()
    if not settings.supabase_jwt_secret:
        raise jwt.InvalidTokenError("no shared secret configured")
    return jwt.decode(
        token,
        settings.supabase_jwt_secret,
        algorithms=["HS256"],
        audience=_AUDIENCE,
    )


def decode_supabase_jwt(token: str) -> dict:
    """Intenta JWKS (proyectos nuevos) y cae a HS256 (proyectos legacy)."""
    try:
        return _decode_with_jwks(token)
    except jwt.InvalidTokenError:
        return _decode_with_shared_secret(token)


async def require_agent_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Falta el header Authorization")

    token = authorization.split(" ", 1)[1]
    try:
        claims = decode_supabase_jwt(token)
    except jwt.InvalidTokenError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token inválido o expirado")

    agent_id = claims.get("sub")
    if not agent_id:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token sin sub")

    return agent_id


def get_supabase(request: Request) -> SupabaseClient:
    """El cliente se crea una vez en el lifespan de la app (ver main.py) y se
    guarda en app.state. Los tests lo reemplazan asignando un fake ahí
    directamente — no hace falta un dependency_overrides por endpoint."""
    return request.app.state.supabase


def get_mp_client(request: Request) -> MercadoPagoClient:
    return request.app.state.mp_client
