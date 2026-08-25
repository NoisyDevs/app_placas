from uuid import uuid4

from tests.conftest import TEST_AGENT_ID


def _payload(**overrides):
    body = {
        "request_id": str(uuid4()),
        "template_id": "remax.hero_v1",
        "kind": "publicacion",
        "formats": ["feed", "story"],
        "include_contact": True,
    }
    body.update(overrides)
    return body


async def test_first_consume_is_granted(client, fake_supabase):
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="free", status="none")

    response = await client.post("/v1/placas/consume", json=_payload())

    assert response.status_code == 200
    body = response.json()
    assert body["granted"] is True
    assert body["used"] == 1
    assert body["quota_limit"] == 10
    assert body["remaining"] == 9


async def test_same_request_id_is_idempotent_and_does_not_double_charge(client, fake_supabase):
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="free", status="none")
    payload = _payload()

    first = await client.post("/v1/placas/consume", json=payload)
    second = await client.post("/v1/placas/consume", json=payload)

    assert first.status_code == second.status_code == 200
    assert first.json()["used"] == second.json()["used"] == 1


async def test_free_tier_is_denied_with_403_after_ten_placas(client, fake_supabase):
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="free", status="none")

    for _ in range(10):
        response = await client.post("/v1/placas/consume", json=_payload())
        assert response.status_code == 200

    eleventh = await client.post("/v1/placas/consume", json=_payload())

    assert eleventh.status_code == 403
    assert eleventh.json()["detail"]["code"] == "quota_exceeded"
    assert eleventh.json()["detail"]["used"] == 10


async def test_pro_tier_has_no_limit(client, fake_supabase):
    fake_supabase.seed_subscription(TEST_AGENT_ID, tier="pro", status="authorized", current_period_end=None)

    for _ in range(15):
        response = await client.post("/v1/placas/consume", json=_payload())
        assert response.status_code == 200
        assert response.json()["quota_limit"] is None
        assert response.json()["remaining"] is None
