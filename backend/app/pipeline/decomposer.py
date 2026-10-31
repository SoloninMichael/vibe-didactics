"""Didactic Decomposer (Mocked Gemini 4 Argon Multimodal Didactic Engine).

Transforms architectural subsystem hotspots into:
1. Progressive-depth Spiral Explanations (ELI5 Halloween Story -> Junior Dev -> Senior Architect)
2. Counterfactual "Break-It / Remove a Brick" Code Mutations with cartoon chaos simulations
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Union

from app.schemas import (
    BaseModel,
    CounterfactualMutation,
    SpiralExplanations,
    SubsystemHotspot,
)


class DecomposedSubsystem(BaseModel):
    """Combined didactic decomposition payload for a single subsystem hotspot."""

    subsystem_id: str
    spiral_explanations: SpiralExplanations
    break_it_mutation: CounterfactualMutation

    @property
    def counterfactual_mutation(self) -> CounterfactualMutation:
        """Alias for callers accessing `.counterfactual_mutation`."""
        return self.break_it_mutation

    @property
    def mutation(self) -> CounterfactualMutation:
        """Alias for callers accessing `.mutation`."""
        return self.break_it_mutation

    @property
    def explanations(self) -> SpiralExplanations:
        """Alias for callers accessing `.explanations`."""
        return self.spiral_explanations

    def __getitem__(self, key: str) -> Any:
        """Support dictionary-style access (`res['spiral_explanations']`, `res['counterfactual_mutation']`)."""
        if key in ("counterfactual_mutation", "mutation", "break_it_mutation"):
            return self.break_it_mutation
        if key in ("spiral_explanations", "explanations"):
            return self.spiral_explanations
        if key == "subsystem_id":
            return self.subsystem_id
        raise KeyError(key)

    def get(self, key: str, default: Any = None) -> Any:
        try:
            return self[key]
        except KeyError:
            return default


class DidacticDecomposer:
    """Mocked Gemini 4 Argon multimodal didactic engine.

    Decomposes complex AI-generated subsystems into progressive Spiral Curriculum
    explanations and interactive Counterfactual ('Break-It / Remove a Brick') mutations.
    """

    MODEL_ID: str = "gemini-4-argon-didactic-preview"

    def __init__(self) -> None:
        self._spiral_catalog: Dict[str, SpiralExplanations] = self._build_spiral_catalog()
        self._mutation_catalog: Dict[str, CounterfactualMutation] = self._build_mutation_catalog()

    def _build_spiral_catalog(self) -> Dict[str, SpiralExplanations]:
        return {
            "sub_1_carving": SpiralExplanations(
                eli5_child=(
                    "Imagine two hyperactive Robot Knives—Choppy-Bot and Slice-Bot—who both hear a spooky echo "
                    "telling them to carve the exact same giant pumpkin at the same time! Without Bouncer Bat "
                    "standing guard at the chopping block holding the Single Golden Carving Ticket, both robot "
                    "knives would jump on the pumpkin together and chop it into orange mush. Bouncer Bat checks "
                    "the ticket number first and tells the second robot: 'Shoo! Ticket #404 is already being carved!'"
                ),
                junior_dev=(
                    "When a webhook or message queue retries a request after a brief network blip, `carve_pumpkin(req)` "
                    "can receive duplicate payloads carrying the same `idempotency_key`. Before firing the physical "
                    "laser actuator, the service calls `self.lock_store.acquire(req.idempotency_key)` (backed by an "
                    "atomic Redis `SET NX PX` lock) and checks the completed-operation ledger. If the `idempotency_key` "
                    "is already locked or processed, it short-circuits and returns the cached result instead of "
                    "executing the carving G-code twice."
                ),
                senior_architect=(
                    "Relying on a TTL-bound distributed mutex (`lock_store.acquire` with lock TTL) under at-least-once "
                    "delivery introduces a classic split-brain hazard under GC pauses or NTP clock drift. If Worker A "
                    "experiences a stop-the-world pause exceeding the lock TTL, the lock expires and Worker B acquires "
                    "it, causing concurrent physical actuation. Production-grade safety requires pairing the "
                    "`idempotency_key` ledger with monotonically increasing fencing tokens validated directly by the "
                    "downstream CNC actuator controller."
                ),
            ),
            "sub_2_candle_fsm": SpiralExplanations(
                eli5_child=(
                    "Inside our giant Jack-o'-Lantern, a friendly Fire Sprite shouts 'SPARK! Light up!' while a "
                    "mischievous Wind Ghost blows 'PUFF! Go dark!' across the graveyard. Sometimes an old 'PUFF!' "
                    "message gets lost behind a tombstone and arrives late, *after* the candle is already glowing! "
                    "So the lantern checks the secret Page Number stamped on every spell: if an old page number "
                    "shows up late, the lantern giggles and ignores the stale ghost wind so the party stays lit!"
                ),
                junior_dev=(
                    "The `CandleStateMachine` protects transitions (`UNLIT -> IGNITING -> LIT -> EXTINGUISHED`) using "
                    "two ordering guards. First, it filters out-of-order network packets via a monotonic "
                    "`sequence_number` check (`if packet.sequence_number <= self.last_seq: return`). Second, when "
                    "persisting state changes, it runs an Optimistic Concurrency Control (CAS) `version` check "
                    "(`WHERE candle_id = :id AND version = :expected_version`), incrementing `version + 1` so "
                    "concurrent workers cannot overwrite a newer state with a stale read."
                ),
                senior_architect=(
                    "Combining edge-level `sequence_number` rejection with storage-layer Compare-And-Swap (`version` "
                    "check) avoids expensive distributed locks during normal telemetry flow, but introduces a "
                    "trade-off under high-contention broadcast cues: simultaneous writes to a hot shard trigger "
                    "a CAS retry storm unless dampened by jittered exponential backoff. Meanwhile, deterministic "
                    "UDP packet reordering protection via monotonic sequence counters strictly outperforms wall-clock "
                    "Last-Write-Wins (LWW) timestamps, which silently violate FSM invariants under microcontroller clock skew."
                ),
            ),
            "sub_3_candy_saga": SpiralExplanations(
                eli5_child=(
                    "Three Candy Goblins are packing your Ultimate Trick-or-Treat Bag: Choco-Goblin drops in a "
                    "chocolate bar, Gummy-Goblin tosses in sour worms, and Lollipop-Goblin reaches into the third "
                    "cauldron... Uh-oh! The Lollipop Cauldron is jammed shut! Because our rule is 'Every kid gets a "
                    "complete treat bag or their spooky coins back,' the Chief Witch blows her Rewind Whistle, and "
                    "Choco-Goblin and Gummy-Goblin neatly put their candies back on the shelf so nothing gets stuck!"
                ),
                junior_dev=(
                    "Because Chocolate Inventory, Gummy Warehouse, and Chute Actuation live in separate microservices "
                    "without a single shared SQL database transaction, `CandySagaOrchestrator` implements a Saga "
                    "pattern. As each service succeeds, its reservation receipt is appended to `reserved_batches`. "
                    "If step 3 raises an exception, the `except` block calls `self._rollback_reserved(reserved_batches)`, "
                    "iterating in reverse order to fire compensating restock calls and restore eventual consistency."
                ),
                senior_architect=(
                    "Orchestrated Sagas avoid the availability bottlenecks and coordinator blocking of Two-Phase Commit "
                    "(2PC/XA), trading strict ACID Isolation for BASE eventual consistency. Because intermediate "
                    "`RESERVED` states are immediately visible before saga completion, concurrent requests can observe "
                    "transient phantom stock depletion (dirty reads). Consequently, every compensating action in "
                    "`_rollback_reserved` must be idempotent, commutative, and driven by a durable transactional outbox "
                    "so network partitions during rollback never leak permanent inventory reservations."
                ),
            ),
            "sub_4_spooky_sync": SpiralExplanations(
                eli5_child=(
                    "Maestro Bone-Jangles is conducting 500 dancing skeletons to 'Spooky Scary Skeletons'! Every beat, "
                    "he tosses glowing green music notes into a tiny 5-slot Magic Cauldron in front of each skeleton. "
                    "If Skeleton #42 trips on its own funny bone and falls behind, its cauldron fills up to the brim! "
                    "Instead of stopping the whole concert or letting the cauldron explode, the cauldron automatically "
                    "pops out the oldest stale note from the bottom so Skeleton #42 can jump straight to the *newest* "
                    "dance move right on beat with its 499 friends!"
                ),
                junior_dev=(
                    "Each skeleton dancer processes 60Hz motion-capture frames from a bounded `ring_buffer` "
                    "(`collections.deque`). When a consumer lags and `len(self.buffer) >= self.max_capacity`, the "
                    "ingestion loop explicitly calls `self.buffer.popleft()` to evict the oldest unconsumed frame "
                    "before appending the incoming packet. This drop-oldest policy guarantees `O(1)` memory per "
                    "subscriber and caps maximum choreography lag at `max_capacity * 16.6ms`."
                ),
                senior_architect=(
                    "In high-frequency real-time telemetry (60Hz skeletal kinematics across 500 fan-out consumers), "
                    "state freshness strictly dominates historical delivery completeness. Unbounded queues turn "
                    "transient consumer stalls into broker OOM crashes, whereas TCP-style producer backpressure "
                    "induces head-of-line (HoL) blocking that throttles all 499 healthy dancers to the speed of the "
                    "slowest straggler. A bounded `ring_buffer` with drop-oldest load shedding bounds tail latency "
                    "deterministically while sacrificing only obsolete intermediate keyframes."
                ),
            ),
        }

    def _build_mutation_catalog(self) -> Dict[str, CounterfactualMutation]:
        return {
            "sub_1_carving": CounterfactualMutation(
                mutation_id="mut_1_idempotency_guard",
                title="Remove Bouncer Bat's Idempotency Lock Check",
                target_file="services/carving/idempotent_carver.py",
                target_line_range="L54-L56",
                code_line_removed="if not self.lock_store.acquire(req.idempotency_key):",
                what_breaks_in_code=(
                    "Duplicate webhook or queue retry deliveries bypass the distributed mutex and execute laser "
                    "G-code concurrently on the same physical pumpkin unit, causing a race-condition state collision, "
                    "double billing, and overlapping hardware cuts."
                ),
                cartoon_chaos_animation=(
                    "Bouncer Bat vanishes in a puff of smoke! Two manic Robot Knives dive onto the same prize "
                    "Jack-o'-Lantern at 2x speed, sparks flying, slicing it into splattered orange pumpkin puree "
                    "while duplicate 'CARVING_COMPLETE' ribbons rain from the rafters!"
                ),
                severity="CRITICAL",
            ),
            "sub_2_candle_fsm": CounterfactualMutation(
                mutation_id="mut_2_stale_seq_guard",
                title="Delete Out-of-Order Sequence & Version Guard",
                target_file="services/lighting/candle_fsm.py",
                target_line_range="L103-L105",
                code_line_removed="if packet.sequence_number <= self.last_seq:",
                what_breaks_in_code=(
                    "Delayed or reordered UDP packets carrying older `sequence_number` values overwrite newer "
                    "FSM states without rejection (zombie state regression), allowing a stale 'EXTINGUISH' packet "
                    "from 3 seconds ago to kill a newly ignited candle and violate monotonic state invariants."
                ),
                cartoon_chaos_animation=(
                    "A sleepy Zombie Postman shuffles in 5 minutes late with an old 'BLOW OUT CANDLE #1' scroll! "
                    "Because nobody checks the scroll's sequence number, all the Jack-o'-Lanterns violently flicker "
                    "between pitch-black darkness and blinding strobe fire in a chaotic graveyard disco glitch!"
                ),
                severity="CRITICAL",
            ),
            "sub_3_candy_saga": CounterfactualMutation(
                mutation_id="mut_3_saga_compensation",
                title="Strip Compensating Saga Rollback on Chute Failure",
                target_file="services/TreatDispenser/candy_saga_orchestrator.py",
                target_line_range="L158-L161",
                code_line_removed="self._rollback_reserved(reserved_batches)",
                what_breaks_in_code=(
                    "When the downstream lollipop chute actuator throws a `DispenserFaultError`, upstream chocolate "
                    "and gummy batches that were already reserved never receive compensating release calls. "
                    "Inventory remains permanently stranded in `RESERVED` limbo until vault stock hits zero and "
                    "all subsequent trick-or-treat orders deadlock."
                ),
                cartoon_chaos_animation=(
                    "The Lollipop Chute jams with a loud CLANK! Instead of putting the chocolates back, the Candy "
                    "Goblins freeze in panic clutching armfuls of reserved chocolate bars—refusing to give them to "
                    "kids OR return them to the vault—until mountains of phantom locked candy pile to the ceiling "
                    "and the vault doors burst!"
                ),
                severity="CRITICAL",
            ),
            "sub_4_spooky_sync": CounterfactualMutation(
                mutation_id="mut_4_ring_buffer_eviction",
                title="Remove Ring-Buffer Drop-Oldest Eviction on Full Queue",
                target_file="services/choreography/spooky_sync_bus.py",
                target_line_range="L89-L91",
                code_line_removed="self.buffer.popleft()",
                what_breaks_in_code=(
                    "When a skeleton consumer experiences a transient frame stall and the buffer reaches capacity, "
                    "new 60Hz packets either block the producer (causing head-of-line blocking across all 500 "
                    "skeletons) or accumulate unboundedly in memory, creating multi-second choreography desync "
                    "followed by an Out-Of-Memory (OOM) crash."
                ),
                cartoon_chaos_animation=(
                    "The Magic Cauldron Queue refuses to drop old music notes! Glowing green notes inflate the "
                    "cauldron like an overfilled balloon—Skeleton #42 is stuck doing last Tuesday's Macarena while "
                    "everyone else does the Moonwalk, until KABOOM! The cauldron explodes and sends 500 skeletons "
                    "flying like bowling pins!"
                ),
                severity="CRITICAL",
            ),
        }

    def get_spiral_explanations(self, subsystem: Union[str, SubsystemHotspot]) -> SpiralExplanations:
        """Return the 3-level Spiral Curriculum explanations for a subsystem."""
        sub_id = subsystem.subsystem_id if isinstance(subsystem, SubsystemHotspot) else subsystem
        if sub_id not in self._spiral_catalog:
            raise ValueError(f"Unknown subsystem_id: {sub_id}")
        return self._spiral_catalog[sub_id]

    def get_counterfactual_mutation(self, subsystem: Union[str, SubsystemHotspot]) -> CounterfactualMutation:
        """Return the Counterfactual ('Break-It / Remove a Brick') mutation for a subsystem."""
        sub_id = subsystem.subsystem_id if isinstance(subsystem, SubsystemHotspot) else subsystem
        if sub_id not in self._mutation_catalog:
            raise ValueError(f"Unknown subsystem_id: {sub_id}")
        return self._mutation_catalog[sub_id]

    def decompose_subsystem(self, subsystem: Union[str, SubsystemHotspot]) -> DecomposedSubsystem:
        """Decompose a single subsystem into its SpiralExplanations and CounterfactualMutation."""
        sub_id = subsystem.subsystem_id if isinstance(subsystem, SubsystemHotspot) else subsystem
        return DecomposedSubsystem(
            subsystem_id=sub_id,
            spiral_explanations=self.get_spiral_explanations(sub_id),
            break_it_mutation=self.get_counterfactual_mutation(sub_id),
        )

    def decompose_all(
        self, hotspots: Optional[List[SubsystemHotspot]] = None
    ) -> Dict[str, DecomposedSubsystem]:
        """Decompose all provided hotspots (or all 4 default Halloween subsystems) keyed by `subsystem_id`."""
        target_ids = (
            [h.subsystem_id for h in hotspots]
            if hotspots is not None
            else list(self._spiral_catalog.keys())
        )
        return {sub_id: self.decompose_subsystem(sub_id) for sub_id in target_ids}

    def decompose(
        self, hotspots: Optional[List[SubsystemHotspot]] = None
    ) -> Dict[str, DecomposedSubsystem]:
        """Alias for `decompose_all`."""
        return self.decompose_all(hotspots=hotspots)
