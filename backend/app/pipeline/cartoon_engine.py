"""3D Cartoon & Game Engine Scene Generator for Vibe Didactics.

Translates each Halloween subsystem hotspot into an interactive 3D cartoon stage
(`Scene3DPayload`) featuring custom Halloween actors, packet connections, a 3-Act
animated narrative storyboard with voiceover scripts, and a Counterfactual
"Break-It" chaos mutation.
"""

from __future__ import annotations

from typing import Dict, List

from app.schemas import (
    CounterfactualMutation,
    Scene3DActor,
    Scene3DAnimationStep,
    Scene3DConnection,
    Scene3DPayload,
)


class CartoonSceneEngine:
    """Generates deterministic 3D Cartoon / Game Engine scenes for all 4 chapters."""

    CHAPTER_IDS: List[str] = [
        "sub_1_carving",
        "sub_2_candle_fsm",
        "sub_3_candy_saga",
        "sub_4_spooky_sync",
    ]

    _ALIAS_MAP: Dict[str, str] = {
        "carving_dispatcher": "sub_1_carving",
        "candle_safety_fsm": "sub_2_candle_fsm",
        "candy_router": "sub_3_candy_saga",
        "spooky_sync_engine": "sub_4_spooky_sync",
    }

    def generate_scene(self, chapter_id: str) -> Scene3DPayload:
        """Generate the 3D cartoon scene specification for a chapter."""
        canonical_id = self._ALIAS_MAP.get(chapter_id, chapter_id)
        builders = {
            "sub_1_carving": self._build_carving_scene,
            "sub_2_candle_fsm": self._build_candle_fsm_scene,
            "sub_3_candy_saga": self._build_candy_saga_scene,
            "sub_4_spooky_sync": self._build_spooky_sync_scene,
        }
        if canonical_id not in builders:
            raise ValueError(
                f"Unknown chapter_id '{chapter_id}'. Expected one of {self.CHAPTER_IDS}."
            )
        return builders[canonical_id]()

    def build_scene(self, chapter_id: str) -> Scene3DPayload:
        """Alias for generate_scene(chapter_id)."""
        return self.generate_scene(chapter_id)

    def get_scene(self, chapter_id: str) -> Scene3DPayload:
        """Alias for generate_scene(chapter_id)."""
        return self.generate_scene(chapter_id)

    def generate_all_scenes(self) -> Dict[str, Scene3DPayload]:
        """Generate a dictionary mapping all 4 chapter IDs to their 3D scenes."""
        return {cid: self.generate_scene(cid) for cid in self.CHAPTER_IDS}

    def build_all_scenes(self) -> Dict[str, Scene3DPayload]:
        """Alias for generate_all_scenes()."""
        return self.generate_all_scenes()

    def list_scenes(self) -> List[Scene3DPayload]:
        """Return all 4 chapter scenes in canonical order."""
        return [self.generate_scene(cid) for cid in self.CHAPTER_IDS]

    def _build_carving_scene(self) -> Scene3DPayload:
        chapter_id = "sub_1_carving"
        return Scene3DPayload(
            chapter_id=chapter_id,
            scene_title="The Haunted CO2 Laser Carving Foundry",
            halloween_theme_setting=(
                "A neon-lit gothic pumpkin foundry where Bouncer Bats guard the "
                "idempotency velvet rope while precision CO2 laser rigs carve fractal grins."
            ),
            video_storyboard_url=f"/api/v1/scenes/{chapter_id}/stream.mp4",
            interactive_player_url=f"/scene-player/{chapter_id}",
            actors=[
                Scene3DActor(
                    actor_id="actor_svg_cauldron",
                    name="SVG Stencil Cauldron Queue",
                    role_metaphor="Bubbling intake cauldron receiving kids' Jack-o'-Lantern SVG uploads",
                    code_symbol="PumpkinCarvingRequest",
                    file_path="mock_halloween_app/models.py",
                    line_range="L39-L47",
                    shape_type="cauldron_queue",
                    color_hex="#FF7518",
                    position=[-6.0, 0.0, 0.0],
                ),
                Scene3DActor(
                    actor_id="actor_idempotency_bat",
                    name="Idempotency Bouncer Bat",
                    role_metaphor="Velvet-rope vampire bat blocking duplicate network retry requests",
                    code_symbol="IdempotencyLockStore.acquire_or_get_cached",
                    file_path="mock_halloween_app/carving_dispatcher.py",
                    line_range="L67-L83",
                    shape_type="bouncer_bat",
                    color_hex="#9D4EDD",
                    position=[-3.0, 0.4, 0.4],
                ),
                Scene3DActor(
                    actor_id="actor_token_bat",
                    name="Token-Bucket Gatekeeper Bat",
                    role_metaphor="Traffic-warden bat dispensing glowing plasma tokens per household",
                    code_symbol="TokenBucketRateLimiter.consume",
                    file_path="mock_halloween_app/carving_dispatcher.py",
                    line_range="L39-L55",
                    shape_type="bouncer_bat",
                    color_hex="#00F5D4",
                    position=[0.0, 0.2, -0.3],
                ),
                Scene3DActor(
                    actor_id="actor_caliper_pumpkin",
                    name="Structural Caliper Pumpkin-Bot",
                    role_metaphor="Inspector pumpkin measuring shell wall thickness vs. fractal kerf density",
                    code_symbol="LaserCarvingDispatcher.validate_svg_geometry",
                    file_path="mock_halloween_app/carving_dispatcher.py",
                    line_range="L110-L129",
                    shape_type="pumpkin_bot",
                    color_hex="#FFB703",
                    position=[3.0, 0.0, 0.3],
                ),
                Scene3DActor(
                    actor_id="actor_co2_laser_rig",
                    name="Sharded CO2 Laser Carver",
                    role_metaphor="High-wattage industrial laser turret etching validated pumpkin shells",
                    code_symbol="LaserCarvingDispatcher.dispatch",
                    file_path="mock_halloween_app/carving_dispatcher.py",
                    line_range="L131-L158",
                    shape_type="laser_carver",
                    color_hex="#FF0055",
                    position=[6.0, 0.0, 0.0],
                ),
            ],
            connections=[
                Scene3DConnection(
                    from_actor_id="actor_svg_cauldron",
                    to_actor_id="actor_idempotency_bat",
                    label="idempotency_key lookup",
                    packet_type="SVG_CARVE_REQ",
                    color_hex="#FF7518",
                ),
                Scene3DConnection(
                    from_actor_id="actor_idempotency_bat",
                    to_actor_id="actor_token_bat",
                    label="in-flight lock acquired",
                    packet_type="LOCK_LEASE_TOKEN",
                    color_hex="#9D4EDD",
                ),
                Scene3DConnection(
                    from_actor_id="actor_token_bat",
                    to_actor_id="actor_caliper_pumpkin",
                    label="1.0 or 2.0 burst tokens spent",
                    packet_type="RATE_OK_SIGNAL",
                    color_hex="#00F5D4",
                ),
                Scene3DConnection(
                    from_actor_id="actor_caliper_pumpkin",
                    to_actor_id="actor_co2_laser_rig",
                    label="kerf load < max_supported_load",
                    packet_type="VALIDATED_VECTOR_PATH",
                    color_hex="#FF0055",
                ),
            ],
            steps=[
                Scene3DAnimationStep(
                    step_index=1,
                    act_title="Act 1: The Trigger — Concurrent SVG Request & Idempotency Lock",
                    Active_actor_ids=["actor_svg_cauldron", "actor_idempotency_bat"],
                    packet_flow="actor_svg_cauldron -> actor_idempotency_bat",
                    voiceover_narration=(
                        "Kids flood the foundry with Haunted Castle Fractal SVGs over laggy Wi-Fi! "
                        "Before the laser ever warms up, our Idempotency Bouncer Bat checks if "
                        "this idempotency_key already finished or has an active in-flight lock."
                    ),
                    code_highlight_file="mock_halloween_app/carving_dispatcher.py",
                    code_highlight_lines="L67-L83",
                    code_snippet=(
                        "if idempotency_key in self._completed_results:\n"
                        "    return False, self._completed_results[idempotency_key]\n"
                        "expires_at = self._active_locks.get(idempotency_key)\n"
                        "if expires_at is not None and expires_at > current_time:\n"
                        "    raise DuplicateCarvingError(f\"In-flight laser pass already active for key={idempotency_key}\")"
                    ),
                    duration_seconds=5.5,
                ),
                Scene3DAnimationStep(
                    step_index=2,
                    act_title="Act 2: The Core Guard/Mechanism — Token-Bucket Burst & Kerf Physics Check",
                    Active_actor_ids=["actor_token_bat", "actor_caliper_pumpkin"],
                    packet_flow="actor_token_bat -> actor_caliper_pumpkin",
                    voiceover_narration=(
                        "Next, the Token-Bucket Bat charges 2.0 burst tokens for fractal patterns so "
                        "one household cannot melt the optics. Then the Caliper Pumpkin-Bot verifies "
                        "the pumpkin shell is at least 12mm thick and can support the vector kerf load."
                    ),
                    code_highlight_file="mock_halloween_app/carving_dispatcher.py",
                    code_highlight_lines="L117-L126",
                    code_snippet=(
                        "multiplier = self.STYLE_COMPLEXITY_MULTIPLIER[request.face_style]\n"
                        "effective_kerf_load = (request.svg_vector_points * multiplier) / max(request.pumpkin_diameter_cm, 10.0)\n"
                        "max_supported_load = request.shell_thickness_mm * 3.2\n"
                        "if effective_kerf_load > max_supported_load:\n"
                        "    raise StructuralCollapseRiskError(f\"Kerf load {effective_kerf_load:.1f} exceeds structural limit\")"
                    ),
                    duration_seconds=6.0,
                ),
                Scene3DAnimationStep(
                    step_index=3,
                    act_title="Act 3: Edge Case & Safety Net — Thermal Feed Throttle & Atomic Lock Commit",
                    Active_actor_ids=["actor_caliper_pumpkin", "actor_co2_laser_rig", "actor_idempotency_bat"],
                    packet_flow="actor_caliper_pumpkin -> actor_co2_laser_rig",
                    voiceover_narration=(
                        "When kerf density exceeds 80% of the structural limit, the dispatcher attaches "
                        "a HIGH_THERMAL_DENSITY warning to throttle laser feed rate by 25%, carves on a "
                        "consistent-hashed rig shard, and atomically caches the result while releasing the lock."
                    ),
                    code_highlight_file="mock_halloween_app/carving_dispatcher.py",
                    code_highlight_lines="L85-L90",
                    code_snippet=(
                        "def commit_result(self, idempotency_key: str, result: CarvingResult) -> None:\n"
                        "    with self._mutex:\n"
                        "        self._completed_results[idempotency_key] = result\n"
                        "        self._active_locks.pop(idempotency_key, None)"
                    ),
                    duration_seconds=5.5,
                ),
            ],
            break_it_mutation=CounterfactualMutation(
                mutation_id="mut_carving_no_inflight_lock",
                title="Remove In-Flight Idempotency Lock Check",
                target_file="mock_halloween_app/carving_dispatcher.py",
                target_line_range="L76-L80",
                code_line_removed="if expires_at is not None and expires_at > current_time: raise DuplicateCarvingError(...)",
                what_breaks_in_code=(
                    "Concurrent network retries bypass the in-flight check before the first carving job "
                    "commits to _completed_results, dispatching two simultaneous laser passes on the same pumpkin."
                ),
                cartoon_chaos_animation=(
                    "The Idempotency Bouncer Bat falls asleep! Two duplicate SVG packets sprint past the velvet rope "
                    "at once, causing twin CO2 laser beams to cross-fire and slice the Pumpkin-Bot cleanly in half!"
                ),
                severity="CRITICAL",
            ),
        )

    def _build_candle_fsm_scene(self) -> Scene3DPayload:
        chapter_id = "sub_2_candle_fsm"
        return Scene3DPayload(
            chapter_id=chapter_id,
            scene_title="The Smart Jack-o'-Lantern Thermal Watchtower",
            halloween_theme_setting=(
                "A windswept porch of glowing IoT Jack-o'-Lanterns monitored by sequence-checking "
                "Bouncer Bats and rapid-response CO2 Fire Extinguisher Ghosts."
            ),
            video_storyboard_url=f"/api/v1/scenes/{chapter_id}/stream.mp4",
            interactive_player_url=f"/scene-player/{chapter_id}",
            actors=[
                Scene3DActor(
                    actor_id="actor_udp_telemetry_cauldron",
                    name="UDP Telemetry Stream Cauldron",
                    role_metaphor="High-frequency cauldron spitting out UDP temperature and wind packets",
                    code_symbol="CandleTelemetryPacket",
                    file_path="mock_halloween_app/models.py",
                    line_range="L61-L67",
                    shape_type="cauldron_queue",
                    color_hex="#3A86FF",
                    position=[-6.0, 0.0, 0.0],
                ),
                Scene3DActor(
                    actor_id="actor_monotonic_bat",
                    name="Sequence Monotonicity Bouncer Bat",
                    role_metaphor="Chronological guard bat swatting away out-of-order UDP packets",
                    code_symbol="CandleSafetyStateMachine.process_telemetry",
                    file_path="mock_halloween_app/candle_safety_fsm.py",
                    line_range="L114-L128",
                    shape_type="bouncer_bat",
                    color_hex="#8338EC",
                    position=[-3.0, 0.5, 0.3],
                ),
                Scene3DActor(
                    actor_id="actor_flame_fsm_pumpkin",
                    name="Flame Safety FSM Pumpkin-Bot",
                    role_metaphor="Smart Jack-o'-Lantern transitioning between FLICKERING_NORMAL and LOCKOUT",
                    code_symbol="CandleSafetyStateMachine",
                    file_path="mock_halloween_app/candle_safety_fsm.py",
                    line_range="L84-L169",
                    shape_type="pumpkin_bot",
                    color_hex="#FF6B00",
                    position=[0.0, 0.0, 0.0],
                ),
                Scene3DActor(
                    actor_id="actor_thermal_breaker_bat",
                    name="Thermal Circuit Breaker Bat",
                    role_metaphor="Breaker switch bat tripping OPEN after 3 consecutive overheat faults",
                    code_symbol="ThermalCircuitBreaker.allow_ignition",
                    file_path="mock_halloween_app/candle_safety_fsm.py",
                    line_range="L48-L73",
                    shape_type="bouncer_bat",
                    color_hex="#FB5607",
                    position=[3.0, 0.4, -0.3],
                ),
                Scene3DActor(
                    actor_id="actor_extinguisher_ghost",
                    name="Micro-CO2 Extinguisher Ghost",
                    role_metaphor="Spectral firefighter blasting an emergency CO2 puff on >85C or >12m/s gusts",
                    code_symbol="SafetyTransitionEvent",
                    file_path="mock_halloween_app/candle_safety_fsm.py",
                    line_range="L135-L143",
                    shape_type="fire_extinguisher_ghost",
                    color_hex="#00F5D4",
                    position=[6.0, 0.6, 0.0],
                ),
            ],
            connections=[
                Scene3DConnection(
                    from_actor_id="actor_udp_telemetry_cauldron",
                    to_actor_id="actor_monotonic_bat",
                    label="UDP seq_num check",
                    packet_type="UDP_TELEMETRY_FRAME",
                    color_hex="#3A86FF",
                ),
                Scene3DConnection(
                    from_actor_id="actor_monotonic_bat",
                    to_actor_id="actor_flame_fsm_pumpkin",
                    label="strictly newer seq_num",
                    packet_type="ORDERED_SENSOR_STATE",
                    color_hex="#8338EC",
                ),
                Scene3DConnection(
                    from_actor_id="actor_flame_fsm_pumpkin",
                    to_actor_id="actor_thermal_breaker_bat",
                    label="record_fault / record_success",
                    packet_type="BREAKER_SIGNAL",
                    color_hex="#FB5607",
                ),
                Scene3DConnection(
                    from_actor_id="actor_flame_fsm_pumpkin",
                    to_actor_id="actor_extinguisher_ghost",
                    label="temp > 85C or wind > 12m/s",
                    packet_type="CO2_EMERGENCY_PUFF",
                    color_hex="#00F5D4",
                ),
            ],
            steps=[
                Scene3DAnimationStep(
                    step_index=1,
                    act_title="Act 1: The Trigger — High-Frequency UDP Telemetry & Sequence Filtering",
                    Active_actor_ids=["actor_udp_telemetry_cauldron", "actor_monotonic_bat"],
                    packet_flow="actor_udp_telemetry_cauldron -> actor_monotonic_bat",
                    voiceover_narration=(
                        "IoT candles blast UDP packets across the porch, and network jitter often delivers "
                        "them out of order! The Sequence Bouncer Bat checks sequence_number against "
                        "last_sequence_number and drops any delayed packets on sight."
                    ),
                    code_highlight_file="mock_halloween_app/candle_safety_fsm.py",
                    code_highlight_lines="L120-L128",
                    code_snippet=(
                        "if packet.sequence_number <= session.last_sequence_number:\n"
                        "    return session.state, None\n"
                        "session.last_sequence_number = packet.sequence_number\n"
                        "if session.state == CandleState.EXTINGUISHED_LOCKOUT:\n"
                        "    return session.state, None"
                    ),
                    duration_seconds=5.5,
                ),
                Scene3DAnimationStep(
                    step_index=2,
                    act_title="Act 2: The Core Guard/Mechanism — Deterministic Flame FSM & CO2 Cutoff",
                    Active_actor_ids=["actor_flame_fsm_pumpkin", "actor_extinguisher_ghost"],
                    packet_flow="actor_flame_fsm_pumpkin -> actor_extinguisher_ghost",
                    voiceover_narration=(
                        "When a spooky autumn gale hits 12 m/s or internal temperature exceeds 85 Celsius, "
                        "the FSM transitions straight into EXTINGUISHED_LOCKOUT and summons the "
                        "Fire Extinguisher Ghost to fire a micro-CO2 puff!"
                    ),
                    code_highlight_file="mock_halloween_app/candle_safety_fsm.py",
                    code_highlight_lines="L135-L143",
                    code_snippet=(
                        "if flame_active and (\n"
                        "    packet.internal_temp_celsius > self.MAX_SAFE_TEMP_CELSIUS\n"
                        "    or packet.wind_speed_mps > self.MAX_SAFE_WIND_MPS\n"
                        "):\n"
                        "    next_state = CandleState.EXTINGUISHED_LOCKOUT\n"
                        "    co2_triggered = True\n"
                        "    self.breaker.record_fault(now=now)"
                    ),
                    duration_seconds=6.0,
                ),
                Scene3DAnimationStep(
                    step_index=3,
                    act_title="Act 3: Edge Case & Safety Net — Circuit Breaker Cooldown & Half-Open Probe",
                    Active_actor_ids=["actor_thermal_breaker_bat", "actor_flame_fsm_pumpkin"],
                    packet_flow="actor_flame_fsm_pumpkin -> actor_thermal_breaker_bat",
                    voiceover_narration=(
                        "After 3 consecutive faults, the Thermal Circuit Breaker trips OPEN to block "
                        "re-ignition across the porch. Only after the 30-second cooldown expires does it "
                        "enter HALF_OPEN to test a single guarded ignition."
                    ),
                    code_highlight_file="mock_halloween_app/candle_safety_fsm.py",
                    code_highlight_lines="L48-L57",
                    code_snippet=(
                        "if self.state == BreakerState.OPEN and self.last_tripped_at is not None:\n"
                        "    if current_time - self.last_tripped_at >= self.cooldown_seconds:\n"
                        "        self.state = BreakerState.HALF_OPEN\n"
                        "        return True\n"
                        "    return False"
                    ),
                    duration_seconds=5.5,
                ),
            ],
            break_it_mutation=CounterfactualMutation(
                mutation_id="mut_candle_no_seq_guard",
                title="Disable Monotonic UDP Sequence Filter & Terminal Lockout Guard",
                target_file="mock_halloween_app/candle_safety_fsm.py",
                target_line_range="L121-L128",
                code_line_removed="if packet.sequence_number <= session.last_sequence_number: return session.state, None",
                what_breaks_in_code=(
                    "A delayed UDP packet carrying an older 45C nominal reading arrives after a 92C spike "
                    "and transitions the pumpkin back to FLICKERING_NORMAL while overheating."
                ),
                cartoon_chaos_animation=(
                    "A sluggish snail-mail UDP packet slips past the Bouncer Bat after an overheat alarm, "
                    "shoving the Fire Extinguisher Ghost aside and reigniting the Jack-o'-Lantern into a "
                    "roaring porch fireball!"
                ),
                severity="CRITICAL",
            ),
        )

    def _build_candy_saga_scene(self) -> Scene3DPayload:
        chapter_id = "sub_3_candy_saga"
        return Scene3DPayload(
            chapter_id=chapter_id,
            scene_title="The Allergy-Safe Candy Vault & Saga Rollback Cauldron",
            halloween_theme_setting=(
                "A bustling trick-or-treat candy vault where an Allergy Bouncer Bat, a Skeleton Saga "
                "Conductor, and a CAS-guarded Candy Vault coordinate multi-SKU treat bags."
            ),
            video_storyboard_url=f"/api/v1/scenes/{chapter_id}/stream.mp4",
            interactive_player_url=f"/scene-player/{chapter_id}",
            actors=[
                Scene3DActor(
                    actor_id="actor_trick_or_treater_bot",
                    name="Trick-or-Treater Pumpkin-Bot",
                    role_metaphor="Costumed kid bot arriving with an allergy profile and multi-candy wish list",
                    code_symbol="TrickOrTreaterOrder",
                    file_path="mock_halloween_app/models.py",
                    line_range="L80-L85",
                    shape_type="pumpkin_bot",
                    color_hex="#FF9F1C",
                    position=[-6.0, 0.0, 0.0],
                ),
                Scene3DActor(
                    actor_id="actor_allergy_bouncer_bat",
                    name="Allergy Cross-Contamination Bouncer Bat",
                    role_metaphor="Bio-scanner bat checking direct and shared-chute trace allergens",
                    code_symbol="AllergyGuardFilter.verify_safe",
                    file_path="mock_halloween_app/candy_router.py",
                    line_range="L63-L78",
                    shape_type="bouncer_bat",
                    color_hex="#FF006E",
                    position=[-3.0, 0.5, 0.4],
                ),
                Scene3DActor(
                    actor_id="actor_occ_candy_vault",
                    name="CAS Optimistic Candy Vault",
                    role_metaphor="Version-stamped cauldron vault enforcing compare-and-swap reservations",
                    code_symbol="CandyInventoryStore.reserve_cas",
                    file_path="mock_halloween_app/candy_router.py",
                    line_range="L94-L109",
                    shape_type="candy_vault",
                    color_hex="#06D6A0",
                    position=[0.0, 0.0, 0.0],
                ),
                Scene3DActor(
                    actor_id="actor_saga_skeleton",
                    name="Saga Coordinator Skeleton Conductor",
                    role_metaphor="Bony transaction maestro orchestrating multi-SKU commits and reverse rollbacks",
                    code_symbol="CandyDispatchSaga.execute_order",
                    file_path="mock_halloween_app/candy_router.py",
                    line_range="L131-L174",
                    shape_type="skeleton_conductor",
                    color_hex="#9B5DE5",
                    position=[3.0, 0.3, -0.3],
                ),
                Scene3DActor(
                    actor_id="actor_dlq_cauldron",
                    name="Dead-Letter Queue (DLQ) Cauldron",
                    role_metaphor="Glowing recovery cauldron catching failed orders after compensating rollbacks",
                    code_symbol="CandyInventoryStore.compensate_return",
                    file_path="mock_halloween_app/candy_router.py",
                    line_range="L111-L116",
                    shape_type="cauldron_queue",
                    color_hex="#EF476F",
                    position=[6.0, 0.0, 0.0],
                ),
            ],
            connections=[
                Scene3DConnection(
                    from_actor_id="actor_trick_or_treater_bot",
                    to_actor_id="actor_allergy_bouncer_bat",
                    label="allergies + requested_candy_skus",
                    packet_type="TRICK_OR_TREAT_ORDER",
                    color_hex="#FF9F1C",
                ),
                Scene3DConnection(
                    from_actor_id="actor_allergy_bouncer_bat",
                    to_actor_id="actor_occ_candy_vault",
                    label="zero allergen intersection",
                    packet_type="SAFE_SKU_RESERVE",
                    color_hex="#FF006E",
                ),
                Scene3DConnection(
                    from_actor_id="actor_occ_candy_vault",
                    to_actor_id="actor_saga_skeleton",
                    label="CAS version++ or conflict",
                    packet_type="CAS_VERSION_RECEIPT",
                    color_hex="#06D6A0",
                ),
                Scene3DConnection(
                    from_actor_id="actor_saga_skeleton",
                    to_actor_id="actor_dlq_cauldron",
                    label="reversed(committed_steps) rollback + DLQ",
                    packet_type="COMPENSATING_ROLLBACK",
                    color_hex="#EF476F",
                ),
            ],
            steps=[
                Scene3DAnimationStep(
                    step_index=1,
                    act_title="Act 1: The Trigger — Multi-SKU Order & Chute Trace Allergy Check",
                    Active_actor_ids=["actor_trick_or_treater_bot", "actor_allergy_bouncer_bat"],
                    packet_flow="actor_trick_or_treater_bot -> actor_allergy_bouncer_bat",
                    voiceover_narration=(
                        "A Trick-or-Treater Pumpkin-Bot arrives with a peanut allergy requesting three candy SKUs! "
                        "Before touching inventory, the Allergy Bouncer Bat unions direct batch allergens "
                        "with shared factory chute traces to guarantee zero cross-contamination."
                    ),
                    code_highlight_file="mock_halloween_app/candy_router.py",
                    code_highlight_lines="L69-L78",
                    code_snippet=(
                        "batch_allergens: Set[AllergyTag] = set(batch.allergens) | self._shared_chute_traces.get(\n"
                        "    batch.sku_id, set()\n"
                        ")\n"
                        "conflicts = kid_allergies.intersection(batch_allergens)\n"
                        "if conflicts:\n"
                        "    raise AllergyContaminationError(f\"Allergy conflict for kid '{order.kid_id}'\")"
                    ),
                    duration_seconds=5.5,
                ),
                Scene3DAnimationStep(
                    step_index=2,
                    act_title="Act 2: The Core Guard/Mechanism — Optimistic Concurrency Control (CAS)",
                    Active_actor_ids=["actor_occ_candy_vault", "actor_saga_skeleton"],
                    packet_flow="actor_occ_candy_vault -> actor_saga_skeleton",
                    voiceover_narration=(
                        "Multiple neighborhood porches dip into the Candy Vault simultaneously! Instead of "
                        "slow database locks, the vault checks if batch.version matches expected_version, "
                        "decrements stock atomically, and bumps the version counter."
                    ),
                    code_highlight_file="mock_halloween_app/candy_router.py",
                    code_highlight_lines="L94-L109",
                    code_snippet=(
                        "if batch.version != expected_version:\n"
                        "    raise VersionConflictError(f\"CAS version mismatch on '{sku_id}'\")\n"
                        "if batch.available_units < quantity:\n"
                        "    raise StockDepletionError(f\"Cauldron depleted for '{sku_id}'\")\n"
                        "batch.available_units -= quantity\n"
                        "batch.version += 1"
                    ),
                    duration_seconds=6.0,
                ),
                Scene3DAnimationStep(
                    step_index=3,
                    act_title="Act 3: Edge Case & Safety Net — Reverse Compensating Saga Rollback & DLQ",
                    Active_actor_ids=["actor_saga_skeleton", "actor_occ_candy_vault", "actor_dlq_cauldron"],
                    packet_flow="actor_saga_skeleton -> actor_dlq_cauldron",
                    voiceover_narration=(
                        "If the third candy in a kid's bag triggers a VersionConflictError or allergy alert, "
                        "the Skeleton Conductor runs compensating transactions in reverse order—returning "
                        "every reserved bar to the vault and filing a DeadLetterEntry for manual refill!"
                    ),
                    code_highlight_file="mock_halloween_app/candy_router.py",
                    code_highlight_lines="L148-L161",
                    code_snippet=(
                        "except CandyDispatchError as exc:\n"
                        "    for prev_sku, prev_qty in reversed(committed_steps):\n"
                        "        new_ver = self.inventory.compensate_return(prev_sku, prev_qty)\n"
                        "        rollback_log.append(f\"Returned {prev_qty}x '{prev_sku}' to cauldron (v{new_ver})\")\n"
                        "    self.dead_letter_queue.append(DeadLetterEntry(order=order, failed_sku_id=sku_id, ...))"
                    ),
                    duration_seconds=6.0,
                ),
            ],
            break_it_mutation=CounterfactualMutation(
                mutation_id="mut_candy_no_saga_rollback",
                title="Remove Reverse-Order Saga Compensating Rollback Loop",
                target_file="mock_halloween_app/candy_router.py",
                target_line_range="L149-L153",
                code_line_removed="for prev_sku, prev_qty in reversed(committed_steps): self.inventory.compensate_return(prev_sku, prev_qty)",
                what_breaks_in_code=(
                    "When the final SKU in a multi-item order fails validation or CAS, the earlier SKUs "
                    "remain permanently deducted from CandyInventoryStore even though the order failed."
                ),
                cartoon_chaos_animation=(
                    "The Skeleton Conductor drops his baton! Half-filled candy bags vanish into phantom "
                    "limbo while the Candy Vault drains to zero—leaving every trick-or-treater empty-handed!"
                ),
                severity="CRITICAL",
            ),
        )

    def _build_spooky_sync_scene(self) -> Scene3DPayload:
        chapter_id = "sub_4_spooky_sync"
        return Scene3DPayload(
            chapter_id=chapter_id,
            scene_title="The 500-Skeleton Graveyard Symphony & Ring Buffer Stage",
            halloween_theme_setting=(
                "A moonlit graveyard stage where a Maestro Skeleton Conductor broadcasts 60fps "
                "128-BPM choreography through bounded cauldron ring buffers to 500 dancing props."
            ),
            video_storyboard_url=f"/api/v1/scenes/{chapter_id}/stream.mp4",
            interactive_player_url=f"/scene-player/{chapter_id}",
            actors=[
                Scene3DActor(
                    actor_id="actor_maestro_conductor",
                    name="128-BPM Maestro Skeleton Conductor",
                    role_metaphor="Symphony conductor computing sine-wave bone angles at 60 frames per second",
                    code_symbol="SpookyAnimatronicSyncHub.synthesize_choreography_frame",
                    file_path="mock_halloween_app/spooky_sync_engine.py",
                    line_range="L127-L148",
                    shape_type="skeleton_conductor",
                    color_hex="#F72585",
                    position=[-6.0, 0.0, 0.0],
                ),
                Scene3DActor(
                    actor_id="actor_ring_buffer_cauldron",
                    name="Drop-Oldest Ring Buffer Cauldron",
                    role_metaphor="Fixed-capacity cauldron evicting the oldest frame when Wi-Fi backpressure builds",
                    code_symbol="BoundedFrameRingBuffer.push_frame",
                    file_path="mock_halloween_app/spooky_sync_engine.py",
                    line_range="L34-L45",
                    shape_type="cauldron_queue",
                    color_hex="#7209B7",
                    position=[-2.5, 0.0, 0.4],
                ),
                Scene3DActor(
                    actor_id="actor_drift_bouncer_bat",
                    name="Clock-Drift Window Bouncer Bat",
                    role_metaphor="Timing referee bat discarding frames older than the 50ms drift window",
                    code_symbol="BoundedFrameRingBuffer.pop_next_valid_frame",
                    file_path="mock_halloween_app/spooky_sync_engine.py",
                    line_range="L47-L65",
                    shape_type="bouncer_bat",
                    color_hex="#4CC9F0",
                    position=[1.0, 0.5, -0.3],
                ),
                Scene3DActor(
                    actor_id="actor_jitter_fog_ghost",
                    name="EMA Jitter-Compensating Fog Ghost",
                    role_metaphor="Floating mist spirit smoothing clock offset and network jitter via EMA",
                    code_symbol="SpookyAnimatronicSyncHub.update_node_clock_telemetry",
                    file_path="mock_halloween_app/spooky_sync_engine.py",
                    line_range="L116-L125",
                    shape_type="fire_extinguisher_ghost",
                    color_hex="#06D6A0",
                    position=[3.5, 0.4, 0.3],
                ),
                Scene3DActor(
                    actor_id="actor_graveyard_dancer_bot",
                    name="Graveyard Animatronic Pumpkin-Bot",
                    role_metaphor="Wireless graveyard prop snapping jaw and xylophone bones right on the beat",
                    code_symbol="SpookyAnimatronicSyncHub.broadcast_frame_nonblocking",
                    file_path="mock_halloween_app/spooky_sync_engine.py",
                    line_range="L150-L180",
                    shape_type="pumpkin_bot",
                    color_hex="#FFBE0B",
                    position=[6.0, 0.0, 0.0],
                ),
            ],
            connections=[
                Scene3DConnection(
                    from_actor_id="actor_maestro_conductor",
                    to_actor_id="actor_ring_buffer_cauldron",
                    label="60fps 128-BPM keyframes",
                    packet_type="CHOREOGRAPHY_FRAME",
                    color_hex="#F72585",
                ),
                Scene3DConnection(
                    from_actor_id="actor_ring_buffer_cauldron",
                    to_actor_id="actor_drift_bouncer_bat",
                    label="popleft() candidate frame",
                    packet_type="BUFFERED_KEYFRAME",
                    color_hex="#7209B7",
                ),
                Scene3DConnection(
                    from_actor_id="actor_jitter_fog_ghost",
                    to_actor_id="actor_drift_bouncer_bat",
                    label="clock_offset_ms + jitter_ema_ms",
                    packet_type="COMPENSATED_CLOCK",
                    color_hex="#06D6A0",
                ),
                Scene3DConnection(
                    from_actor_id="actor_drift_bouncer_bat",
                    to_actor_id="actor_graveyard_dancer_bot",
                    label="drift_ms <= 50ms beat-locked",
                    packet_type="SYNCED_SERVO_COMMAND",
                    color_hex="#FFBE0B",
                ),
            ],
            steps=[
                Scene3DAnimationStep(
                    step_index=1,
                    act_title="Act 1: The Trigger — 128-BPM Beat Phase Synthesis & Non-Blocking Fanout",
                    Active_actor_ids=["actor_maestro_conductor", "actor_ring_buffer_cauldron"],
                    packet_flow="actor_maestro_conductor -> actor_ring_buffer_cauldron",
                    voiceover_narration=(
                        "To the 128-BPM beat of 'Spooky Scary Skeletons', the Maestro Conductor computes "
                        "jaw chatter, ribcage sway, and fog bursts at 60fps, pushing frames into each "
                        "node's ring buffer without ever awaiting slow graveyard Wi-Fi!"
                    ),
                    code_highlight_file="mock_halloween_app/spooky_sync_engine.py",
                    code_highlight_lines="L131-L138",
                    code_snippet=(
                        "beats_per_ms = bpm / 60_000.0\n"
                        "beat_phase = (timestamp_ms * beats_per_ms) * (2.0 * math.pi)\n"
                        "ribcage_sway = round(math.sin(beat_phase) * 28.5, 2)\n"
                        "jaw_chatter = round(abs(math.cos(beat_phase * 2.0)) * 42.0, 2)"
                    ),
                    duration_seconds=5.5,
                ),
                Scene3DAnimationStep(
                    step_index=2,
                    act_title="Act 2: The Core Guard/Mechanism — Bounded Ring Buffer with Drop-Oldest Eviction",
                    Active_actor_ids=["actor_ring_buffer_cauldron", "actor_drift_bouncer_bat"],
                    packet_flow="actor_ring_buffer_cauldron -> actor_drift_bouncer_bat",
                    voiceover_narration=(
                        "When damp graveyard mist slows down Node #402's Wi-Fi, its 12-frame Ring Buffer "
                        "Cauldron fills up. Instead of eating all the Raspberry Pi's RAM, push_frame "
                        "evicts the oldest frame from the left so fresh choreography always wins!"
                    ),
                    code_highlight_file="mock_halloween_app/spooky_sync_engine.py",
                    code_highlight_lines="L39-L45",
                    code_snippet=(
                        "evicted_oldest = len(self._buffer) == self.capacity\n"
                        "if evicted_oldest:\n"
                        "    self._buffer.popleft()\n"
                        "    self.dropped_frames_count += 1\n"
                        "self._buffer.append(frame)"
                    ),
                    duration_seconds=6.0,
                ),
                Scene3DAnimationStep(
                    step_index=3,
                    act_title="Act 3: Edge Case & Safety Net — EMA Jitter Compensation & 50ms Stale Frame Pruning",
                    Active_actor_ids=["actor_jitter_fog_ghost", "actor_drift_bouncer_bat", "actor_graveyard_dancer_bot"],
                    packet_flow="actor_drift_bouncer_bat -> actor_graveyard_dancer_bot",
                    voiceover_narration=(
                        "Finally, the Fog Ghost applies exponential moving average clock-offset and jitter "
                        "compensation, while the Drift Bouncer Bat discards any frame more than 50ms behind "
                        "the beat—keeping all 500 skeletons dancing in razor-sharp unison!"
                    ),
                    code_highlight_file="mock_halloween_app/spooky_sync_engine.py",
                    code_highlight_lines="L58-L65",
                    code_snippet=(
                        "while self._buffer:\n"
                        "    candidate = self._buffer.popleft()\n"
                        "    drift_ms = reference_clock_ms - candidate.timestamp_ms\n"
                        "    if drift_ms <= max_drift_ms:\n"
                        "        return candidate, stale_discarded\n"
                        "    stale_discarded += 1"
                    ),
                    duration_seconds=5.5,
                ),
            ],
            break_it_mutation=CounterfactualMutation(
                mutation_id="mut_sync_unbounded_buffer",
                title="Remove Bounded Ring Buffer Drop-Oldest Eviction & 50ms Drift Filter",
                target_file="mock_halloween_app/spooky_sync_engine.py",
                target_line_range="L39-L43",
                code_line_removed="if evicted_oldest: self._buffer.popleft()",
                what_breaks_in_code=(
                    "Slow Wi-Fi animatronic nodes accumulate thousands of stale 60fps frames in memory, "
                    "triggering Raspberry Pi OOM crashes and causing skeletons to dance 4 seconds behind the music."
                ),
                cartoon_chaos_animation=(
                    "The Ring Buffer Cauldron overflows with glowing purple keyframes until it explodes in a "
                    "green OOM smoke cloud, while all 500 skeletons flail wildly off-beat and tangling their ribcages!"
                ),
                severity="CRITICAL",
            ),
        )
