"""Fixtures compartidas.

Nota importante: `FakeSupabaseClient.rpc("consume_placa_credit", ...)` replica
en Python el contrato de la función SQL homónima (supabase/schema.sql) para
poder testear la orquestación del router sin una base de datos viva. Es una
prueba de contrato, no una prueba de la función SQL real — esa se verifica
aparte, contra Postgres, cuando Docker esté disponible (ver ARCHITECTURE.md
§4 y el pendiente anotado en el chat de instalación del entorno).
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from app.deps import require_agent_id
from app.main import app
from app.services.mercadopago import MpPreapprovalStatus, PreapprovalResult

TEST_AGENT_ID = "11111111-1111-4111-8111-111111111111"


class FakeSupabaseClient:
    def __init__(self) -> None:
        self.subscriptions: dict[str, dict[str, Any]] = {}
        self._placa_events: list[dict[str, Any]] = []
        self._webhook_event_ids: set[str] = set()

    def seed_subscription(self, agent_id: str, **fields: Any) -> None:
        self.subscriptions[agent_id] = {
            "agent_id": agent_id,
            "tier": "free",
            "status": "none",
            "mp_preapproval_id": None,
            "current_period_end": None,
            **fields,
        }

    def _period_start(self) -> datetime:
        now = datetime.now(timezone.utc)
        return now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    async def rpc(self, function_name: str, params: dict[str, Any]) -> Any:
        assert function_name == "consume_placa_credit"
        agent_id = params["p_agent"]
        request_id = params["p_request"]

        existing = [
            e for e in self._placa_events
            if e["agent_id"] == agent_id and e["client_request_id"] == request_id
        ]
        used_in_period = [
            e for e in self._placa_events
            if e["agent_id"] == agent_id and e["created_at"] >= self._period_start()
        ]

        sub = self.subscriptions.setdefault(agent_id, {"tier": "free", "status": "none", "current_period_end": None})
        is_unlimited = sub["tier"] == "pro" and (
            sub["current_period_end"] is None or sub["current_period_end"] > datetime.now(timezone.utc)
        )
        quota_limit = None if is_unlimited else 10

        if existing:
            return [{"granted": True, "reason": "replay", "used": len(used_in_period), "quota_limit": quota_limit}]

        if quota_limit is not None and len(used_in_period) >= quota_limit:
            return [{"granted": False, "reason": "quota_exceeded", "used": len(used_in_period), "quota_limit": quota_limit}]

        self._placa_events.append(
            {
                "agent_id": agent_id,
                "client_request_id": request_id,
                "created_at": datetime.now(timezone.utc),
            }
        )
        return [{"granted": True, "reason": "granted", "used": len(used_in_period) + 1, "quota_limit": quota_limit}]

    async def select_one(self, table: str, *, agent_id: str) -> dict[str, Any] | None:
        assert table == "subscriptions"
        return self.subscriptions.get(agent_id)

    async def update_one(self, table: str, *, agent_id: str, patch: dict[str, Any]) -> None:
        assert table == "subscriptions"
        row = self.subscriptions.setdefault(agent_id, {"agent_id": agent_id})
        row.update(patch)

    async def insert_ignore_conflict(self, table: str, *, row: dict[str, Any], on_conflict: str) -> bool:
        assert table == "mp_webhook_events"
        event_id = row["mp_event_id"]
        if event_id in self._webhook_event_ids:
            return False
        self._webhook_event_ids.add(event_id)
        return True


class FakeMercadoPagoClient:
    def __init__(self) -> None:
        # preapproval_id -> (status, external_reference)
        self.preapprovals: dict[str, tuple[MpPreapprovalStatus, str | None]] = {}
        self._counter = 0
        self.cancel_calls: list[str] = []

    def seed_preapproval(
        self, preapproval_id: str, status: MpPreapprovalStatus, *, external_reference: str = TEST_AGENT_ID
    ) -> None:
        self.preapprovals[preapproval_id] = (status, external_reference)

    async def create_preapproval(self, *, payer_email, external_reference, reason, back_url):
        self._counter += 1
        preapproval_id = f"fake-preapproval-{self._counter}"
        self.preapprovals[preapproval_id] = ("pending", external_reference)
        return PreapprovalResult(
            preapproval_id=preapproval_id,
            status="pending",
            init_point="https://mp.example/checkout",
            external_reference=external_reference,
        )

    async def get_preapproval(self, preapproval_id: str) -> PreapprovalResult:
        status, external_reference = self.preapprovals[preapproval_id]
        return PreapprovalResult(
            preapproval_id=preapproval_id, status=status, external_reference=external_reference
        )

    async def cancel_preapproval(self, preapproval_id: str) -> PreapprovalResult:
        self.cancel_calls.append(preapproval_id)
        _, external_reference = self.preapprovals[preapproval_id]
        self.preapprovals[preapproval_id] = ("cancelled", external_reference)
        return PreapprovalResult(
            preapproval_id=preapproval_id, status="cancelled", external_reference=external_reference
        )


@pytest.fixture
def fake_supabase() -> FakeSupabaseClient:
    return FakeSupabaseClient()


@pytest.fixture
def fake_mp() -> FakeMercadoPagoClient:
    return FakeMercadoPagoClient()


@pytest_asyncio.fixture
async def client(fake_supabase: FakeSupabaseClient, fake_mp: FakeMercadoPagoClient):
    app.state.supabase = fake_supabase
    app.state.mp_client = fake_mp
    app.dependency_overrides[require_agent_id] = lambda: TEST_AGENT_ID

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()
