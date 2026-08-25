import hashlib
import hmac

from app.services.mp_signature import build_manifest, verify_mp_signature

SECRET = "test-webhook-secret"


def _sign(data_id: str, request_id: str, ts: str) -> str:
    manifest = build_manifest(data_id=data_id, request_id=request_id, ts=ts)
    return hmac.new(SECRET.encode(), manifest.encode(), hashlib.sha256).hexdigest()


def test_valid_signature_is_accepted():
    v1 = _sign("123", "req-1", "1700000000")
    header = f"ts=1700000000,v1={v1}"
    assert verify_mp_signature(
        x_signature=header, x_request_id="req-1", data_id="123", secret=SECRET
    )


def test_tampered_data_id_is_rejected():
    v1 = _sign("123", "req-1", "1700000000")
    header = f"ts=1700000000,v1={v1}"
    assert not verify_mp_signature(
        x_signature=header, x_request_id="req-1", data_id="999", secret=SECRET
    )


def test_wrong_secret_is_rejected():
    v1 = _sign("123", "req-1", "1700000000")
    header = f"ts=1700000000,v1={v1}"
    assert not verify_mp_signature(
        x_signature=header, x_request_id="req-1", data_id="123", secret="wrong-secret"
    )


def test_missing_v1_is_rejected():
    assert not verify_mp_signature(
        x_signature="ts=1700000000", x_request_id="req-1", data_id="123", secret=SECRET
    )


def test_malformed_header_is_rejected():
    assert not verify_mp_signature(
        x_signature="garbage-not-key-value", x_request_id="req-1", data_id="123", secret=SECRET
    )
