"""Subsystem 1: Automated Laser-Guided Pumpkin Carving Dispatcher.

Controls high-power CO2 laser carving rigs on Halloween night. Must enforce:
1. Token-bucket burst rate limiting per household so laser optics don't overheat.
2. Distributed idempotency locks so network retries never double-carve a single pumpkin.
3. Structural wall-thickness validation against fractal SVG vector density.
"""

from __future__ import annotations

import threading
import time
from typing import Dict, Optional, Tuple

from .models import CarvingResult, PumpkinCarvingRequest, PumpkinFaceStyle


class RateLimitExceededError(RuntimeError):
    """Raised when a household exceeds its laser-rig burst token allocation."""


class DuplicateCarvingError(RuntimeError):
    """Raised when a concurrent retry attempts to carve an already-locked pumpkin."""


class StructuralCollapseRiskError(ValueError):
    """Raised when SVG complexity is too dense for the pumpkin's shell thickness."""


class TokenBucketRateLimiter:
    """Controls burst traffic of kids uploading Jack-o'-Lantern SVG patterns."""

    def __init__(self, capacity: float = 5.0, refill_rate_per_sec: float = 0.5) -> None:
        self.capacity = capacity
        self.refill_rate_per_sec = refill_rate_per_sec
        self._buckets: Dict[str, Tuple[float, float]] = {}
        self._lock = threading.Lock()

    def consume(self, household_id: str, tokens: float = 1.0, now: Optional[float] = None) -> bool:
        """Attempts to consume tokens for a household; refills proportionally to elapsed time."""
        current_time = time.monotonic() if now is None else now
        with self._lock:
            available, last_updated = self._buckets.get(household_id, (self.capacity, current_time))
            elapsed = max(0.0, current_time - last_updated)
            replenished = min(self.capacity, available + elapsed * self.refill_rate_per_sec)
            if replenished < tokens:
                self._buckets[household_id] = (replenished, current_time)
                return False

            self._buckets[household_id] = (replenished - tokens, current_time)
            return True


class IdempotencyLockStore:
    """Prevents duplicate laser-carving requests from slicing the same pumpkin in half."""

    def __init__(self, ttl_seconds: float = 300.0) -> None:
        self.ttl_seconds = ttl_seconds
        self._active_locks: Dict[str, float] = {}
        self._completed_results: Dict[str, CarvingResult] = {}
        self._mutex = threading.Lock()

    def acquire_or_get_cached(
        self, idempotency_key: str, now: Optional[float] = None
    ) -> Tuple[bool, Optional[CarvingResult]]:
        """Atomically acquires the lock for `idempotency_key` or returns a cached result."""
        current_time = time.monotonic() if now is None else now
        with self._mutex:
            if idempotency_key in self._completed_results:
                return False, self._completed_results[idempotency_key]

            expires_at = self._active_locks.get(idempotency_key)
            if expires_at is not None and expires_at > current_time:
                raise DuplicateCarvingError(
                    f"In-flight laser pass already active for key={idempotency_key}"
                )

            self._active_locks[idempotency_key] = current_time + self.ttl_seconds
            return True, None

    def commit_result(self, idempotency_key: str, result: CarvingResult) -> None:
        """Stores the finished carving result and releases the active in-flight lock."""
        with self._mutex:
            self._completed_results[idempotency_key] = result
            self._active_locks.pop(idempotency_key, None)


class LaserCarvingDispatcher:
    """Validates SVG structural physics and dispatches idempotent jobs to CO2 laser rigs."""

    STYLE_COMPLEXITY_MULTIPLIER: Dict[PumpkinFaceStyle, float] = {
        PumpkinFaceStyle.CLASSIC_GRIN: 1.0,
        PumpkinFaceStyle.VAMPIRE_FANGS: 1.35,
        PumpkinFaceStyle.WITCH_SILHOUETTE: 1.75,
        PumpkinFaceStyle.HAUNTED_CASTLE_FRACTAL: 2.6,
    }

    def __init__(
        self,
        rate_limiter: Optional[TokenBucketRateLimiter] = None,
        lock_store: Optional[IdempotencyLockStore] = None,
    ) -> None:
        self.rate_limiter = rate_limiter or TokenBucketRateLimiter()
        self.lock_store = lock_store or IdempotencyLockStore()

    def validate_svg_geometry(self, request: PumpkinCarvingRequest) -> Optional[str]:
        """Checks vector density against shell thickness to prevent pumpkin bridge collapse."""
        if request.shell_thickness_mm < 12.0:
            raise StructuralCollapseRiskError(
                f"Shell thickness {request.shell_thickness_mm}mm is below 12mm minimum."
            )

        multiplier = self.STYLE_COMPLEXITY_MULTIPLIER[request.face_style]
        effective_kerf_load = (request.svg_vector_points * multiplier) / max(
            request.pumpkin_diameter_cm, 10.0
        )
        max_supported_load = request.shell_thickness_mm * 3.2

        if effective_kerf_load > max_supported_load:
            raise StructuralCollapseRiskError(
                f"Kerf load {effective_kerf_load:.1f} exceeds structural limit {max_supported_load:.1f}"
            )
        if effective_kerf_load > max_supported_load * 0.8:
            return "HIGH_THERMAL_DENSITY: bridge walls < 4mm; reduced laser feed rate by 25%."
        return None

    def dispatch(self, request: PumpkinCarvingRequest) -> CarvingResult:
        """Acquires idempotency lock, enforces rate limit, validates geometry, and carves."""
        acquired, cached_result = self.lock_store.acquire_or_get_cached(request.idempotency_key)
        if not acquired and cached_result is not None:
            return cached_result

        token_cost = 2.0 if request.face_style == PumpkinFaceStyle.HAUNTED_CASTLE_FRACTAL else 1.0
        if not self.rate_limiter.consume(request.household_id, tokens=token_cost):
            raise RateLimitExceededError(
                f"Household {request.household_id} exhausted laser rig burst tokens."
            )

        warning = self.validate_svg_geometry(request)
        rig_shard = sum(ord(ch) for ch in request.household_id) % 4
        duration_ms = int(420 + request.svg_vector_points * 1.8)

        result = CarvingResult(
            request_id=request.request_id,
            idempotency_key=request.idempotency_key,
            laser_rig_id=f"RIG-CO2-0{rig_shard + 1}",
            carved_successfully=True,
            duration_ms=duration_ms,
            warning=warning,
        )
        self.lock_store.commit_result(request.idempotency_key, result)
        return result
