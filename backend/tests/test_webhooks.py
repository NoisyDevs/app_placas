import hashlib
import hmac

from app.services.mp_signature import build_manifest
from tests.conftest import TEST_AGENT_ID

WEBHOOK_SECRET = "local-dev-webhook-secret"  # default en app/config.py


def _signed_request(data_id: str, request_id: str = "req-1", ts: str = "1700000000"):
    manifest = build_manifest(data_id=data_id, request_id=request_id, ts=ts)
    v1 = hmac.new(WEBHOOK_SECRET.encode(), manifest.encode(), hashlib.sha256).hexdigest()
    headers = {"x-signature": f"ts={ts},v1={v1}", "x-request-id": request_id}
    body = {"type": "subscription_preapproval", "data": {"id": data_id}}
    return headers, body


async def test_invalid_signature_is_rejected(client):
    headers = {"x-signature": "ts=1,v1=deadbeef", "x-request-id": "req-1"}
    response = await client.post(
        "/v1/webhooks/mercadopago",
        json={"type": "subscription_preapproval", "data": {"id": "pre-123"}},
        headers=headers,
    )
    assert response.status_code == 401


async def test_applies_authorized_transition(client, fake_supabase, fake_mp):
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="free", status="pending")
    fake_mp.seed_preapproval("pre-123", "authorized", external_reference=TEST_AGENT_ID)
    headers, body = _signed_request("pre-123")

    response = await client.post("/v1/webhooks/mercadopago", json=body, headers=headers)

    assert response.status_code == 200
    assert response.json()["status"] == "applied"
    updated = fake_supabase.subscriptions[TEST_AGENT_ID]
    assert updated["tier"] == "pro"
    assert updated["status"] == "authorized"


async def test_duplicate_delivery_is_processed_only_once(client, fake_supabase, fake_mp):
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="free", status="pending")
    fake_mp.seed_preapproval("pre-123", "authorized", external_reference=TEST_AGENT_ID)
    headers, body = _signed_request("pre-123")

    first = await client.post("/v1/webhooks/mercadopago", json=body, headers=headers)
    second = await client.post("/v1/webhooks/mercadopago", json=body, headers=headers)

    assert first.json()["status"] == "applied"
    assert second.json()["status"] == "already_processed"


async def test_courtesy_account_is_never_touched_by_mp_webhook(client, fake_supabase, fake_mp):
    fake_supabase.seed_subscription(
        TEST_AGENT_ID, tier="pro", status="courtesy", current_period_end=None
    )
    fake_mp.seed_preapproval("pre-123", "cancelled", external_reference=TEST_AGENT_ID)
    headers, body = _signed_request("pre-123")

    response = await client.post("/v1/webhooks/mercadopago", json=body, headers=headers)

    assert response.status_code == 200
    assert response.json()["status"] == "ignored_courtesy_account"
    still_courtesy = fake_supabase.subscriptions[TEST_AGENT_ID]
    assert still_courtesy["tier"] == "pro"
    assert still_courtesy["status"] == "courtesy"


async def test_out_of_order_delivery_is_harmless_because_state_is_refetched(
    client, fake_supabase, fake_mp
):
    """Simula que un 'paused' viejo llega después de que MP ya autorizó: como
    el handler siempre re-consulta el estado actual a MP (no confía en el
    payload), el resultado refleja la realidad ('authorized'), no el evento
    potencialmente stale que disparó la entrega."""
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="pro", status="authorized")
    fake_mp.seed_preapproval("pre-123", "authorized", external_reference=TEST_AGENT_ID)
    headers, body = _signed_request("pre-123", request_id="req-stale-paused-event")

    response = await client.post("/v1/webhooks/mercadopago", json=body, headers=headers)

    assert response.status_code == 200
    updated = fake_supabase.subscriptions[TEST_AGENT_ID]
    assert updated["status"] == "authorized"


async def test_unknown_agent_does_not_crash(client, fake_supabase, fake_mp):
    fake_mp.seed_preapproval("pre-999", "authorized", external_reference="agent-not-in-db")
    headers, body = _signed_request("pre-999")

    response = await client.post("/v1/webhooks/mercadopago", json=body, headers=headers)

    assert response.status_code == 200
    assert response.json()["status"] == "unknown_agent"
