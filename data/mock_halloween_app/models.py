"""Domain models for the Mock Halloween Pumpkin & Party Preparation Platform (SpookyPrep-OS).

This codebase represents a complex AI-generated ("vibe-coded") distributed system
that a developer needs to understand before merging to production on October 31st.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Dict, List, Optional


class PumpkinFaceStyle(str, Enum):
    CLASSIC_GRIN = "classic_grin"
    VAMPIRE_FANGS = "vampire_fangs"
    WITCH_SILHOUETTE = "witch_silhouette"
    HAUNTED_CASTLE_FRACTAL = "haunted_castle_fractal"


class CandleState(str, Enum):
    UNLIT = "UNLIT"
    IGNITING = "IGNITING"
    FLICKERING_NORMAL = "FLICKERING_NORMAL"
    WIND_GUST_ALERT = "WIND_GUST_ALERT"
    THERMAL_OVERHEAT = "THERMAL_OVERHEAT"
    EXTINGUISHED_LOCKOUT = "EXTINGUISHED_LOCKOUT"


class AllergyTag(str, Enum):
    PEANUT = "peanut"
    TREE_NUT = "tree_nut"
    GLUTEN = "gluten"
    DAIRY = "dairy"


@dataclass
class PumpkinCarvingRequest:
    request_id: str
    idempotency_key: str
    household_id: str
    pumpkin_diameter_cm: float
    shell_thickness_mm: float
    face_style: PumpkinFaceStyle
    svg_vector_points: int
    requested_at: datetime = field(default_factory=datetime.utcnow)


@dataclass
class CarvingResult:
    request_id: str
    idempotency_key: str
    laser_rig_id: str
    carved_successfully: bool
    duration_ms: int
    warning: Optional[str] = None


@dataclass
class CandleTelemetryPacket:
    pumpkin_id: str
    internal_temp_celsius: float
    wind_speed_mps: float
    oxygen_ratio: float
    battery_mv: int
    sequence_number: int


@dataclass
class CandySkuBatch:
    sku_id: str
    candy_name: str
    allergens: List[AllergyTag]
    available_units: int
    version: int = 1  # Used for Optimistic Concurrency Control


@dataclass
class TrickOrTreaterOrder:
    kid_id: str
    costume_name: str
    allergies: List[AllergyTag]
    requested_candy_skus: Dict[str, int]
    house_zone: str


@dataclass
class AnimatronicFrame:
    frame_id: int
    timestamp_ms: int
    bpm: int
    skeleton_joint_angles: Dict[str, float]
    fog_machine_intensity: float
