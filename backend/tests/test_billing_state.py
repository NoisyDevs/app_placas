from datetime import datetime, timedelta, timezone

import pytest

from app.services.billing_state import (
    CourtesyAccountError,
    UnknownMercadoPagoStatusError,
    apply_mp_status,
)


def test_pending_maps_to_free_pending():
    patch = apply_mp_status(current_status="none", mp_status="pending")
    assert (patch.tier, patch.status) == ("free", "pending")
    assert patch.current_period_end is None


def test_authorized_maps_to_pro_with_period_end():
    patch = apply_mp_status(current_status="pending", mp_status="authorized")
    assert (patch.tier, patch.status) == ("pro", "authorized")
    assert patch.current_period_end is not None
    assert patch.current_period_end > datetime.now(timezone.utc)


def test_authorized_never_reuses_a_stale_previous_period_end():
    """Una fecha vieja (de un ciclo pasado) nunca debe reaparecer como la
    nueva fecha de corte: 'authorized' siempre calcula una fecha fresca."""
    stale = datetime.now(timezone.utc) - timedelta(days=40)
    patch = apply_mp_status(
        current_status="paused", mp_status="authorized", previous_period_end=stale
    )
    assert patch.current_period_end is not None
    assert patch.current_period_end > datetime.now(timezone.utc)


def test_paused_preserves_previous_period_end_for_lazy_downgrade():
    """paused/cancelled NO bajan a free inmediatamente: conservan tier='pro'
    y el current_period_end previo, y quota_status() en Postgres hace el
    downgrade perezoso comparando esa fecha contra now()."""
    previous_end = datetime.now(timezone.utc) + timedelta(days=12)
    patch = apply_mp_status(
        current_status="authorized", mp_status="paused", previous_period_end=previous_end
    )
    assert patch.tier == "pro"
    assert patch.status == "paused"
    assert patch.current_period_end == previous_end


def test_cancelled_keeps_pro_tier_and_previous_period_end():
    previous_end = datetime.now(timezone.utc) + timedelta(days=3)
    patch = apply_mp_status(
        current_status="authorized", mp_status="cancelled", previous_period_end=previous_end
    )
    assert patch.tier == "pro"
    assert patch.status == "cancelled"
    assert patch.current_period_end == previous_end


def test_cancelled_without_a_previous_period_end_downgrades_immediately():
    """Si nunca hubo un current_period_end guardado (no debería pasar en la
    práctica, pero es el caso borde), no hay gracia que preservar."""
    patch = apply_mp_status(
        current_status="pending", mp_status="cancelled", previous_period_end=None
    )
    assert patch.current_period_end is None


def test_courtesy_account_rejects_any_mp_transition():
    with pytest.raises(CourtesyAccountError):
        apply_mp_status(current_status="courtesy", mp_status="cancelled")


def test_unknown_mp_status_is_rejected_not_silently_applied():
    with pytest.raises(UnknownMercadoPagoStatusError):
        apply_mp_status(current_status="pending", mp_status="some_new_status_mp_added")
