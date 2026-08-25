from tests.conftest import TEST_AGENT_ID


async def test_status_returns_seeded_subscription(client, fake_supabase):
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="pro", status="authorized")

    response = await client.get("/v1/billing/status")

    assert response.status_code == 200
    assert response.json()["tier"] == "pro"
    assert response.json()["status"] == "authorized"


async def test_status_404_when_no_subscription_row(client, fake_supabase):
    response = await client.get("/v1/billing/status")
    assert response.status_code == 404


async def test_subscribe_creates_preapproval_and_sets_pending(client, fake_supabase, fake_mp):
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="free", status="none")

    response = await client.post(
        "/v1/billing/subscribe", json={"payer_email": "agente@example.com"}
    )

    assert response.status_code == 200
    body = response.json()
    assert body["preapproval_id"].startswith("fake-preapproval-")
    assert body["init_point"] == "https://mp.example/checkout"

    updated = fake_supabase.subscriptions[TEST_AGENT_ID]
    assert updated["status"] == "pending"
    assert updated["mp_preapproval_id"] == body["preapproval_id"]


async def test_subscribe_rejects_courtesy_accounts(client, fake_supabase, fake_mp):
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="pro", status="courtesy")

    response = await client.post(
        "/v1/billing/subscribe", json={"payer_email": "agente@example.com"}
    )

    assert response.status_code == 409
    assert fake_mp.preapprovals == {}  # nunca se llegó a llamar a MP


async def test_cancel_calls_mercadopago_with_stored_preapproval_id(client, fake_supabase, fake_mp):
    fake_supabase.seed_subscription(
        TEST_AGENT_ID, tier="pro", status="authorized", mp_preapproval_id="pre-123"
    )
    fake_mp.seed_preapproval("pre-123", "authorized")

    response = await client.post("/v1/billing/cancel")

    assert response.status_code == 204
    assert fake_mp.cancel_calls == ["pre-123"]


async def test_cancel_rejects_courtesy_accounts(client, fake_supabase, fake_mp):
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="pro", status="courtesy")

    response = await client.post("/v1/billing/cancel")

    assert response.status_code == 409
    assert fake_mp.cancel_calls == []
