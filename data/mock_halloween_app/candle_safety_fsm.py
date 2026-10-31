"""Subsystem 2: Smart Jack-o'-Lantern Candle Safety FSM & Thermal Circuit Breaker.

Processes high-frequency UDP telemetry from IoT candle inserts, enforces strict
sequence-number ordering to prevent out-of-order packets from clearing lockouts,
and coordinates micro-CO2 puff extinguishers when thermal or wind thresholds trip.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple

from .models import CandleState, CandleTelemetryPacket


class BreakerState(str, Enum):
    CLOSED = "CLOSED"
    OPEN = "OPEN"
    HALF_OPEN = "HALF_OPEN"


@dataclass
class SafetyTransitionEvent:
    pumpkin_id: str
    previous_state: CandleState
    new_state: CandleState
    sequence_number: int
    co2_puff_triggered: bool
    reason: str


class ThermalCircuitBreaker:
    """Monitors consecutive overheat or sensor-drop faults across smart Jack-o'-Lanterns."""

    def __init__(
        self,
        failure_threshold: int = 3,
        cooldown_seconds: float = 30.0,
    ) -> None:
        self.failure_threshold = failure_threshold
        self.cooldown_seconds = cooldown_seconds
        self.state: BreakerState = BreakerState.CLOSED
        self.consecutive_failures: int = 0
        self.last_tripped_at: Optional[float] = None

    def allow_ignition(self, now: Optional[float] = None) -> bool:
        current_time = now if now is not None else time.monotonic()
        if self.state == BreakerState.CLOSED:
            return True
        if self.state == BreakerState.OPEN and self.last_tripped_at is not None:
            if current_time - self.last_tripped_at >= self.cooldown_seconds:
                self.state = BreakerState.HALF_OPEN
                return True
            return False
        return self.state == BreakerState.HALF_OPEN

    def record_success(self) -> None:
        self.consecutive_failures = 0
        if self.state == BreakerState.HALF_OPEN:
            self.state = BreakerState.CLOSED

    def record_fault(self, now: Optional[float] = None) -> BreakerState:
        current_time = now if now is not None else time.monotonic()
        self.consecutive_failures += 1
        if (
            self.state == BreakerState.HALF_OPEN
            or self.consecutive_failures >= self.failure_threshold
        ):
            self.state = BreakerState.OPEN
            self.last_tripped_at = current_time
        return self.state


@dataclass
class _PumpkinSession:
    state: CandleState = CandleState.UNLIT
    last_sequence_number: int = -1
    co2_discharges: int = 0
    audit_log: List[SafetyTransitionEvent] = field(default_factory=list)


class CandleSafetyStateMachine:
    """Deterministic finite-state machine governing Jack-o'-Lantern flame safety."""

    MAX_SAFE_TEMP_CELSIUS: float = 85.0
    WARNING_TEMP_CELSIUS: float = 72.0
    MAX_SAFE_WIND_MPS: float = 12.0
    GUST_ALERT_WIND_MPS: float = 7.5
    MIN_OXYGEN_RATIO: float = 0.16

    ACTIVE_FLAME_STATES = {
        CandleState.IGNITING,
        CandleState.FLICKERING_NORMAL,
        CandleState.WIND_GUST_ALERT,
        CandleState.THERMAL_OVERHEAT,
    }

    def __init__(self, circuit_breaker: Optional[ThermalCircuitBreaker] = None) -> None:
        self.breaker = circuit_breaker or ThermalCircuitBreaker()
        self._sessions: Dict[str, _PumpkinSession] = {}

    def request_ignition(self, pumpkin_id: str, now: Optional[float] = None) -> CandleState:
        session = self._sessions.setdefault(pumpkin_id, _PumpkinSession())
        if session.state == CandleState.EXTINGUISHED_LOCKOUT:
            return session.state
        if not self.breaker.allow_ignition(now=now):
            session.state = CandleState.EXTINGUISHED_LOCKOUT
            return session.state
        session.state = CandleState.IGNITING
        return session.state

    def process_telemetry(
        self, packet: CandleTelemetryPacket, now: Optional[float] = None
    ) -> Tuple[CandleState, Optional[SafetyTransitionEvent]]:
        """Ingests a UDP telemetry packet while rejecting stale sequence numbers."""
        session = self._sessions.setdefault(packet.pumpkin_id, _PumpkinSession())

        # Drop out-of-order or duplicate UDP packets so stale frames cannot clear lockouts
        if packet.sequence_number <= session.last_sequence_number:
            return session.state, None

        session.last_sequence_number = packet.sequence_number
        prev_state = session.state

        if prev_state == CandleState.EXTINGUISHED_LOCKOUT:
            return prev_state, None

        flame_active = prev_state in self.ACTIVE_FLAME_STATES
        co2_triggered = False
        reason = "nominal_telemetry"
        next_state = prev_state

        if flame_active and (
            packet.internal_temp_celsius > self.MAX_SAFE_TEMP_CELSIUS
            or packet.wind_speed_mps > self.MAX_SAFE_WIND_MPS
        ):
            next_state = CandleState.EXTINGUISHED_LOCKOUT
            co2_triggered = True
            session.co2_discharges += 1
            self.breaker.record_fault(now=now)
            reason = "co2_puff_emergency_cutoff"
        elif flame_active and packet.internal_temp_celsius >= self.WARNING_TEMP_CELSIUS:
            next_state = CandleState.THERMAL_OVERHEAT
            self.breaker.record_fault(now=now)
            reason = "thermal_warning_threshold"
        elif flame_active and packet.wind_speed_mps >= self.GUST_ALERT_WIND_MPS:
            next_state = CandleState.WIND_GUST_ALERT
            reason = "high_wind_gust_detected"
        elif flame_active and packet.oxygen_ratio < self.MIN_OXYGEN_RATIO:
            next_state = CandleState.UNLIT
            reason = "oxygen_depletion_flameout"
        elif flame_active:
            next_state = CandleState.FLICKERING_NORMAL
            self.breaker.record_success()
            reason = "flame_stabilized"

        event = SafetyTransitionEvent(
            pumpkin_id=packet.pumpkin_id,
            previous_state=prev_state,
            new_state=next_state,
            sequence_number=packet.sequence_number,
            co2_puff_triggered=co2_triggered,
            reason=reason,
        )
        session.state = next_state
        session.audit_log.append(event)
        return next_state, event
