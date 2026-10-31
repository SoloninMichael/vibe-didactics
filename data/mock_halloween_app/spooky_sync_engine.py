"""Subsystem 4: Spooky Animatronic Choreography & Real-Time Audio Sync Engine.

Broadcasts 60fps choreography frames synchronized to a 128 BPM "Spooky Scary Skeletons"
audio track across up to 500 wireless graveyard animatronic nodes. Uses a fixed-capacity
ring buffer with a Drop-Oldest backpressure policy and clock-drift jitter compensation
to prevent Raspberry Pi OOM crashes and event-loop stalls when graveyard Wi-Fi degrades.
"""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field
import math
from typing import Deque, Dict, Optional, Tuple

from .models import AnimatronicFrame


class BoundedFrameRingBuffer:
    """Fixed-capacity ring buffer with Drop-Oldest Backpressure Policy.

    Prevents slow Wi-Fi skeleton nodes in the graveyard from causing unbounded
    RAM growth (OOM) on the central Raspberry Pi controller during 60fps bursts.
    """

    def __init__(self, capacity: int = 16) -> None:
        if capacity <= 0:
            raise ValueError("Ring buffer capacity must be strictly positive")
        self.capacity: int = capacity
        self._buffer: Deque[AnimatronicFrame] = deque(maxlen=capacity)
        self.dropped_frames_count: int = 0
        self.total_enqueued_count: int = 0

    def push_frame(self, frame: AnimatronicFrame) -> bool:
        """Enqueue a choreography frame, evicting the oldest frame if at capacity."""
        evicted_oldest = len(self._buffer) == self.capacity
        if evicted_oldest:
            self._buffer.popleft()
            self.dropped_frames_count += 1
        self._buffer.append(frame)
        self.total_enqueued_count += 1
        return evicted_oldest

    def pop_next_valid_frame(
        self, reference_clock_ms: int, max_drift_ms: int = 50
    ) -> Tuple[Optional[AnimatronicFrame], int]:
        """Pop frames until finding one within the acceptable clock-drift window."""
        stale_discarded = 0
        while self._buffer:
            candidate = self._buffer.popleft()
            drift_ms = reference_clock_ms - candidate.timestamp_ms
            if drift_ms <= max_drift_ms:
                return candidate, stale_discarded
            stale_discarded += 1
            self.dropped_frames_count += 1
        return None, stale_discarded

    @property
    def depth(self) -> int:
        return len(self._buffer)


@dataclass
class AnimatronicNodeSession:
    """Tracks per-node buffer and clock drift/jitter telemetry for a wireless prop."""

    node_id: str
    zone: str
    clock_offset_ms: float = 0.0
    jitter_ema_ms: float = 0.0
    ring_buffer: BoundedFrameRingBuffer = field(
        default_factory=lambda: BoundedFrameRingBuffer(capacity=12)
    )
    stale_drops: int = 0
    delivered_frames: int = 0


class SpookyAnimatronicSyncHub:
    """Real-time 60fps choreography broadcaster for 500 graveyard animatronic nodes."""

    TARGET_FPS: int = 60
    DEFAULT_BPM: int = 128

    def __init__(self, max_nodes: int = 500, max_drift_ms: int = 50) -> None:
        self.max_nodes: int = max_nodes
        self.max_drift_ms: int = max_drift_ms
        self._nodes: Dict[str, AnimatronicNodeSession] = {}

    def register_node(
        self, node_id: str, zone: str = "graveyard_west", buffer_capacity: int = 12
    ) -> AnimatronicNodeSession:
        """Register or reset a wireless skeleton/fog node in the sync hub."""
        if node_id not in self._nodes and len(self._nodes) >= self.max_nodes:
            raise RuntimeError(f"Sync hub reached max capacity of {self.max_nodes} nodes")
        session = AnimatronicNodeSession(
            node_id=node_id, zone=zone, ring_buffer=BoundedFrameRingBuffer(buffer_capacity)
        )
        self._nodes[node_id] = session
        return session

    def update_node_clock_telemetry(
        self, node_id: str, master_clock_ms: int, node_reported_ms: int
    ) -> float:
        """Estimate clock drift and exponential moving average (EMA) network jitter."""
        session = self._nodes[node_id]
        instantaneous_offset = float(node_reported_ms - master_clock_ms)
        delta_drift = abs(instantaneous_offset - session.clock_offset_ms)
        session.jitter_ema_ms = 0.8 * session.jitter_ema_ms + 0.2 * delta_drift
        session.clock_offset_ms = 0.85 * session.clock_offset_ms + 0.15 * instantaneous_offset
        return session.jitter_ema_ms

    def synthesize_choreography_frame(
        self, frame_id: int, timestamp_ms: int, bpm: int = DEFAULT_BPM
    ) -> AnimatronicFrame:
        """Compute 128 BPM beat-locked skeleton joint angles and fog intensity."""
        beat_phase = (timestamp_ms * (bpm / 60_000.0)) * (2.0 * math.pi)
        return AnimatronicFrame(
            frame_id=frame_id,
            timestamp_ms=timestamp_ms,
            bpm=bpm,
            skeleton_joint_angles={
                "skull_jaw_deg": round(abs(math.cos(beat_phase * 2.0)) * 42.0, 2),
                "ribcage_tilt_deg": round(math.sin(beat_phase) * 28.5, 2),
                "left_ulna_strike_deg": round(math.sin(beat_phase * 2.0 + 0.5) * 65.0, 2),
            },
            fog_machine_intensity=round(
                max(0.15, math.pow(max(0.0, math.sin(beat_phase / 4.0)), 3)), 3
            ),
        )

    def broadcast_frame_nonblocking(
        self, frame: AnimatronicFrame, master_clock_ms: int
    ) -> Dict[str, int]:
        """Fan out a 60fps frame to all connected nodes without blocking the event loop."""
        backpressure_evictions, stale_drops, dispatched = 0, 0, 0
        for session in self._nodes.values():
            if session.ring_buffer.push_frame(frame):
                backpressure_evictions += 1
            compensated_clock_ms = int(
                master_clock_ms + session.clock_offset_ms + session.jitter_ema_ms
            )
            valid_frame, discarded = session.ring_buffer.pop_next_valid_frame(
                reference_clock_ms=compensated_clock_ms, max_drift_ms=self.max_drift_ms
            )
            session.stale_drops += discarded
            stale_drops += discarded
            if valid_frame is not None:
                session.delivered_frames += 1
                dispatched += 1
        return {
            "connected_nodes": len(self._nodes),
            "dispatched_frames": dispatched,
            "backpressure_evictions": backpressure_evictions,
            "stale_frame_drops": stale_drops,
        }
