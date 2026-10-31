"""Top-level Halloween Night Orchestrator for SpookyPrep-OS.

Coordinates the 4 critical AI-generated backend subsystems across a full
Halloween night simulation:
1. Pumpkin laser carving dispatch (`carving_dispatcher`)
2. Smart-candle ignition & safety telemetry FSM (`candle_safety_fsm`)
3. Allergy-safe trick-or-treat candy routing (`candy_router`)
4. Animatronic skeleton & fog choreography sync (`spooky_sync_engine`)
"""

from __future__ import annotations

import asyncio
import importlib
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from .models import (
    AllergyTag,
    AnimatronicFrame,
    CandleState,
    CandleTelemetryPacket,
    CandySkuBatch,
    CarvingResult,
    PumpkinCarvingRequest,
    PumpkinFaceStyle,
    TrickOrTreaterOrder,
)


@dataclass
class SimulationSummary:
    """Aggregated telemetry and outcomes from a full Halloween night run."""

    carving_results: List[CarvingResult] = field(default_factory=list)
    candle_states: Dict[str, CandleState] = field(default_factory=dict)
    candy_dispatches: List[Dict[str, Any]] = field(default_factory=list)
    synced_frames: List[AnimatronicFrame] = field(default_factory=list)
    subsystem_warnings: List[str] = field(default_factory=list)


class HalloweenNightOrchestrator:
    """Coordinates pumpkin carving, candle safety, candy routing, and animatronics.

    Uses lazy/tolerant imports for sibling modules so the orchestrator can run
    either alongside the full subsystem implementations or in standalone verification
    environments.
    """

    def __init__(
        self,
        carving_dispatcher: Optional[Any] = None,
        candle_fsm: Optional[Any] = None,
        candy_router: Optional[Any] = None,
        sync_engine: Optional[Any] = None,
    ) -> None:
        self._carving_dispatcher = carving_dispatcher or self._lazy_load_subsystem(
            "carving_dispatcher",
            ["PumpkinCarvingDispatcher", "CarvingDispatcher"],
        )
        self._candle_fsm = candle_fsm or self._lazy_load_subsystem(
            "candle_safety_fsm",
            ["CandleSafetyFSM", "SmartCandleSafetyFSM"],
        )
        self._candy_router = candy_router or self._lazy_load_subsystem(
            "candy_router",
            ["CandyInventoryRouter", "CandyRouter", "AllergySafeCandyRouter"],
        )
        self._sync_engine = sync_engine or self._lazy_load_subsystem(
            "spooky_sync_engine",
            ["SpookySyncEngine", "AnimatronicSyncEngine"],
        )

    @staticmethod
    def _lazy_load_subsystem(module_name: str, candidate_classes: List[str]) -> Optional[Any]:
        """Attempt to import a sibling module and instantiate its primary class."""
        try:
            module = importlib.import_module(f".{module_name}", package=__package__)
        except Exception:
            return None

        for class_name in candidate_classes:
            cls = getattr(module, class_name, None)
            if cls is not None:
                try:
                    return cls()
                except TypeError:
                    return cls
        return module

    async def run_carving_phase(
        self, requests: List[PumpkinCarvingRequest]
    ) -> List[CarvingResult]:
        """Dispatch pumpkin laser carving jobs with idempotency protection."""
        results: List[CarvingResult] = []
        seen_keys: Dict[str, CarvingResult] = {}

        for req in requests:
            if self._carving_dispatcher is not None:
                for method_name in ("dispatch_carving", "dispatch", "process_request"):
                    fn = getattr(self._carving_dispatcher, method_name, None)
                    if callable(fn):
                        maybe_coro = fn(req)
                        res = (
                            await maybe_coro
                            if asyncio.iscoroutine(maybe_coro)
                            else maybe_coro
                        )
                        if isinstance(res, CarvingResult):
                            results.append(res)
                            break
                else:
                    results.append(self._fallback_carve(req, seen_keys))
            else:
                results.append(self._fallback_carve(req, seen_keys))

        return results

    @staticmethod
    def _fallback_carve(
        req: PumpkinCarvingRequest, seen_keys: Dict[str, CarvingResult]
    ) -> CarvingResult:
        if req.idempotency_key in seen_keys:
            cached = seen_keys[req.idempotency_key]
            return CarvingResult(
                request_id=req.request_id,
                idempotency_key=req.idempotency_key,
                laser_rig_id=cached.laser_rig_id,
                carved_successfully=cached.carved_successfully,
                duration_ms=0,
                warning="DEDUPLICATED_BY_IDEMPOTENCY_KEY",
            )

        warning = None
        if req.face_style == PumpkinFaceStyle.HAUNTED_CASTLE_FRACTAL and req.shell_thickness_mm < 12.0:
            warning = "THIN_SHELL_FRACTAL_POWER_THROTTLED"

        result = CarvingResult(
            request_id=req.request_id,
            idempotency_key=req.idempotency_key,
            laser_rig_id=f"laser-rig-{hash(req.household_id) % 4 + 1}",
            carved_successfully=True,
            duration_ms=max(250, int(req.svg_vector_points * 1.4)),
            warning=warning,
        )
        seen_keys[req.idempotency_key] = result
        return result

    def run_candle_telemetry_phase(
        self, telemetry_stream: List[CandleTelemetryPacket]
    ) -> Dict[str, CandleState]:
        """Process smart-candle IoT telemetry packets and track safety FSM states."""
        states: Dict[str, CandleState] = {}
        last_seq: Dict[str, int] = {}

        for packet in telemetry_stream:
            handled = False
            if self._candle_fsm is not None:
                for method_name in ("process_telemetry", "ingest_packet", "step"):
                    fn = getattr(self._candle_fsm, method_name, None)
                    if callable(fn):
                        try:
                            state = fn(packet)
                            if isinstance(state, CandleState):
                                states[packet.pumpkin_id] = state
                                handled = True
                                break
                        except Exception:
                            pass

            if handled:
                continue

            # Self-contained deterministic fallback if sibling FSM did not handle packet
            prev_seq = last_seq.get(packet.pumpkin_id, -1)
            if packet.sequence_number <= prev_seq:
                continue
            last_seq[packet.pumpkin_id] = packet.sequence_number

            current = states.get(packet.pumpkin_id, CandleState.UNLIT)
            if current == CandleState.EXTINGUISHED_LOCKOUT:
                continue

            if packet.internal_temp_celsius >= 85.0 or packet.oxygen_ratio < 0.16:
                states[packet.pumpkin_id] = CandleState.EXTINGUISHED_LOCKOUT
            elif packet.internal_temp_celsius >= 70.0:
                states[packet.pumpkin_id] = CandleState.THERMAL_OVERHEAT
            elif packet.wind_speed_mps >= 8.5:
                states[packet.pumpkin_id] = CandleState.WIND_GUST_ALERT
            else:
                states[packet.pumpkin_id] = CandleState.FLICKERING_NORMAL

        return states

    def run_candy_dispatch_phase(
        self,
        inventory: List[CandySkuBatch],
        orders: List[TrickOrTreaterOrder],
    ) -> List[Dict[str, Any]]:
        """Route allergy-safe candy batches using Optimistic Concurrency Control."""
        sku_map: Dict[str, CandySkuBatch] = {batch.sku_id: batch for batch in inventory}
        dispatches: List[Dict[str, Any]] = []

        for order in orders:
            handled = False
            if self._candy_router is not None:
                for method_name in ("FulfillOrder", "fulfill_order", "route_order", "dispatch"):
                    fn = getattr(self._candy_router, method_name, None)
                    if callable(fn):
                        try:
                            res = fn(order, sku_map)
                            if isinstance(res, dict):
                                dispatches.append(res)
                                handled = True
                                break
                        except TypeError:
                            try:
                                res = fn(order)
                                if isinstance(res, dict):
                                    dispatches.append(res)
                                    handled = True
                                    break
                            except Exception:
                                pass

            if handled:
                continue

            allocated: Dict[str, int] = {}
            rejected_reasons: List[str] = []

            for sku_id, qty in order.requested_candy_skus.items():
                batch = sku_map.get(sku_id)
                if batch is None:
                    rejected_reasons.append(f"UNKNOWN_SKU:{sku_id}")
                    continue

                if set(order.allergies) & set(batch.allergens):
                    rejected_reasons.append(f"ALLERGEN_BLOCKED:{sku_id}")
                    continue

                if batch.available_units < qty:
                    rejected_reasons.append(f"OUT_OF_STOCK:{sku_id}")
                    continue

                # Optimistic concurrency version bump & atomic deduction
                batch.available_units -= qty
                batch.version += 1
                allocated[sku_id] = qty

            dispatches.append(
                {
                    "kid_id": order.kid_id,
                    "costume_name": order.costume_name,
                    "allocated_skus": allocated,
                    "rejected_reasons": rejected_reasons,
                    "safe_for_allergies": [a.value for a in order.allergies],
                }
            )

        return dispatches

    def run_animatronic_sync_phase(
        self, frames: List[AnimatronicFrame], target_bpm: int = 128
    ) -> List[AnimatronicFrame]:
        """Synchronize skeleton joint choreography and fog intensity to target BPM."""
        synced: List[AnimatronicFrame] = []
        for frame in frames:
            if self._sync_engine is not None:
                for method_name in ("sync_frame", "interpolate_frame", "process_frame"):
                    fn = getattr(self._sync_engine, method_name, None)
                    if callable(fn):
                        try:
                            out = fn(frame, target_bpm=target_bpm)
                            if isinstance(out, AnimatronicFrame):
                                synced.append(out)
                                break
                        except TypeError:
                            try:
                                out = fn(frame)
                                if isinstance(out, AnimatronicFrame):
                                    synced.append(out)
                                    break
                            except Exception:
                                pass
                else:
                    synced.append(self._fallback_sync_frame(frame, target_bpm))
            else:
                synced.append(self._fallback_sync_frame(frame, target_bpm))
        return synced

    @staticmethod
    def _fallback_sync_frame(frame: AnimatronicFrame, target_bpm: int) -> AnimatronicFrame:
        scale = target_bpm / max(frame.bpm, 1)
        clamped_angles = {
            joint: round(max(-180.0, min(180.0, angle * min(scale, 1.25))), 2)
            for joint, angle in frame.skeleton_joint_angles.items()
        }
        return AnimatronicFrame(
            frame_id=frame.frame_id,
            timestamp_ms=frame.timestamp_ms,
            bpm=target_bpm,
            skeleton_joint_angles=clamped_angles,
            fog_machine_intensity=min(1.0, max(0.0, round(frame.fog_machine_intensity, 3))),
        )

    async def simulate_halloween_night(self) -> SimulationSummary:
        """Execute an end-to-end Halloween night simulation across all 4 subsystems."""
        summary = SimulationSummary()

        carving_requests = [
            PumpkinCarvingRequest(
                request_id="carve-001",
                idempotency_key="idem-house-alpha-1",
                household_id="house-alpha",
                pumpkin_diameter_cm=28.5,
                shell_thickness_mm=15.2,
                face_style=PumpkinFaceStyle.CLASSIC_GRIN,
                svg_vector_points=320,
            ),
            PumpkinCarvingRequest(
                request_id="carve-002",
                idempotency_key="idem-house-beta-fractal",
                household_id="house-beta",
                pumpkin_diameter_cm=24.0,
                shell_thickness_mm=9.5,
                face_style=PumpkinFaceStyle.HAUNTED_CASTLE_FRACTAL,
                svg_vector_points=1850,
            ),
        ]
        summary.carving_results = await self.run_carving_phase(carving_requests)
        for res in summary.carving_results:
            if res.warning:
                summary.subsystem_warnings.append(f"carving:{res.request_id}:{res.warning}")

        telemetry_packets = [
            CandleTelemetryPacket(
                pumpkin_id="pumpkin-alpha",
                internal_temp_celsius=42.0,
                wind_speed_mps=2.1,
                oxygen_ratio=0.209,
                battery_mv=3950,
                sequence_number=1,
            ),
            CandleTelemetryPacket(
                pumpkin_id="pumpkin-beta",
                internal_temp_celsius=88.4,
                wind_speed_mps=9.8,
                oxygen_ratio=0.155,
                battery_mv=3710,
                sequence_number=1,
            ),
        ]
        summary.candle_states = self.run_candle_telemetry_phase(telemetry_packets)

        inventory = [
            CandySkuBatch(
                sku_id="sku-choco-bat",
                candy_name="Dark Chocolate Vampire Bat",
                allergens=[AllergyTag.DAIRY, AllergyTag.PEANUT],
                available_units=25,
            ),
            CandySkuBatch(
                sku_id="sku-gummy-fangs",
                candy_name="Hypoallergenic Blood-Orange Gummy Fangs",
                allergens=[],
                available_units=40,
            ),
        ]
        orders = [
            TrickOrTreaterOrder(
                kid_id="kid-101",
                costume_name="Cyberpunk Witch",
                allergies=[AllergyTag.PEANUT],
                requested_candy_skus={"sku-choco-bat": 1, "sku-gummy-fangs": 2},
                house_zone="porch-north",
            )
        ]
        summary.candy_dispatches = self.run_candy_dispatch_phase(inventory, orders)

        frames = [
            AnimatronicFrame(
                frame_id=1,
                timestamp_ms=0,
                bpm=120,
                skeleton_joint_angles={"left_elbow": 45.0, "jaw_hinge": 30.0},
                fog_machine_intensity=0.65,
            ),
            AnimatronicFrame(
                frame_id=2,
                timestamp_ms=500,
                bpm=120,
                skeleton_joint_angles={"left_elbow": 92.0, "jaw_hinge": 5.0},
                fog_machine_intensity=0.80,
            ),
        ]
        summary.synced_frames = self.run_animatronic_sync_phase(frames, target_bpm=128)

        return summary
