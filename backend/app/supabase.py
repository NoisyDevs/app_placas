"""Cliente delgado hacia PostgREST, autenticado con la service_role key.

Deliberadamente no hay driver de base de datos (psycopg, asyncpg, etc.): todo
pasa por REST/RPC vía httpx. Ver ARCHITECTURE.md §6 — la lista de
dependencias se mantiene chica a propósito.
"""

from __future__ import annotations

from typing import Any

import httpx

from app.config import Settings


class SupabaseError(RuntimeError):
    def __init__(self, message: str, *, status_code: int, body: Any):
        super().__init__(message)
        self.status_code = status_code
        self.body = body


class SupabaseClient:
    def __init__(self, settings: Settings, *, transport: httpx.AsyncBaseTransport | None = None):
        self._settings = settings
        self._client = httpx.AsyncClient(
            base_url=settings.supabase_rest_url,
            headers={
                "apikey": settings.supabase_service_role_key,
                "Authorization": f"Bearer {settings.supabase_service_role_key}",
                "Content-Type": "application/json",
            },
            transport=transport,
            timeout=10.0,
        )

    async def aclose(self) -> None:
        await self._client.aclose()

    async def rpc(self, function_name: str, params: dict[str, Any]) -> Any:
        response = await self._client.post(f"/rpc/{function_name}", json=params)
        if response.is_error:
            raise SupabaseError(
                f"rpc {function_name} falló con {response.status_code}",
                status_code=response.status_code,
                body=_safe_json(response),
            )
        return response.json()

    async def select_one(self, table: str, *, agent_id: str) -> dict[str, Any] | None:
        response = await self._client.get(
            f"/{table}",
            params={"agent_id": f"eq.{agent_id}", "select": "*", "limit": "1"},
        )
        if response.is_error:
            raise SupabaseError(
                f"select {table} falló con {response.status_code}",
                status_code=response.status_code,
                body=_safe_json(response),
            )
        rows = response.json()
        return rows[0] if rows else None

    async def update_one(self, table: str, *, agent_id: str, patch: dict[str, Any]) -> None:
        response = await self._client.patch(
            f"/{table}",
            params={"agent_id": f"eq.{agent_id}"},
            json=patch,
        )
        if response.is_error:
            raise SupabaseError(
                f"update {table} falló con {response.status_code}",
                status_code=response.status_code,
                body=_safe_json(response),
            )

    async def insert_ignore_conflict(self, table: str, *, row: dict[str, Any], on_conflict: str) -> bool:
        """Inserta una fila; devuelve False si ya existía (usado para dedupe)."""
        response = await self._client.post(
            f"/{table}",
            params={"on_conflict": on_conflict},
            json=row,
            headers={"Prefer": "return=representation,resolution=ignore-duplicates"},
        )
        if response.is_error:
            raise SupabaseError(
                f"insert {table} falló con {response.status_code}",
                status_code=response.status_code,
                body=_safe_json(response),
            )
        rows = response.json()
        return len(rows) > 0


def _safe_json(response: httpx.Response) -> Any:
    try:
        return response.json()
    except ValueError:
        return response.text
