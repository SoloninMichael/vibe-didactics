"""Active Recall FlipCard, Socratic Maieutics & Parsons Puzzle Engine.

Generates locked-by-default ChapterDidacticAssessment payloads for the 4 Halloween
subsystems and evaluates developer FlipCard swipe answers (returning child-friendly
Halloween simplified metaphors whenever knew_answer=False).
"""

from __future__ import annotations

from typing import Dict, List, Optional, Tuple, Union

from app.schemas import (
    ChapterDidacticAssessment,
    DidacticTechnique,
    FlipCard,
    FlipCardAnswerRequest,
    FlipCardAnswerResponse,
    ParsonsBlock,
)

LOCKED_ASSESSMENT_REASON = (
    "Watch the 3D Halloween Cartoon Scene first to unlock active recall Flip Cards!"
)


class FlipCardAssessmentEngine:
    """Builds and evaluates Socratic FlipCards and Parsons Puzzles for each chapter."""

    def __init__(self) -> None:
        self._simplified_metaphors_by_card: Dict[str, str] = self._build_card_metaphors()
        self._chapter_fallback_metaphors: Dict[str, str] = {
            "sub_1_carving": (
                "Imagine only 8 monster chefs have carving knives in a tiny kitchen! "
                "A velvet rope bouncer at the door only lets 8 pumpkins inside at a time "
                "so the kitchen table never collapses under 10,000 pumpkins."
            ),
            "sub_2_candle_fsm": (
                "Think of a traffic light inside a Jack-O'-Lantern! It must go from Dark -> "
                "Spark -> Glowing -> Cool-Down in strict order, and if the wind blows it out, "
                "each pumpkin counts to a random number before striking a match so they don't "
                "all spark at once!"
            ),
            "sub_3_candy_saga": (
                "Imagine trading Halloween candy with three friendly ghosts! If the last ghost "
                "drops your bucket, the checklist runs backward to put every chocolate bar back "
                "into the vault so zero candy ever disappears."
            ),
            "sub_4_spooky_sync": (
                "Picture 500 skeletons dancing to one Maestro's glowing baton! Every skeleton "
                "checks how fast or slow its own watch is, and if one skeleton trips on a bone, "
                "the other 499 keep dancing on the beat instead of freezing the whole stage."
            ),
        }

    # ------------------------------------------------------------------
    # Public Assessment Generation API
    # ------------------------------------------------------------------

    def generate_assessment(
        self, chapter_id: str, unlocked: bool = False
    ) -> ChapterDidacticAssessment:
        """Generate the ChapterDidacticAssessment for one of the 4 Halloween chapters."""
        builders = {
            "sub_1_carving": self._build_sub_1_carving,
            "sub_2_candle_fsm": self._build_sub_2_candle_fsm,
            "sub_3_candy_saga": self._build_sub_3_candy_saga,
            "sub_4_spooky_sync": self._build_sub_4_spooky_sync,
        }
        builder = builders.get(chapter_id)
        if builder is None:
            raise ValueError(
                f"Unknown chapter_id '{chapter_id}'. Expected one of: {list(builders.keys())}"
            )
        assessment = builder()
        if unlocked:
            assessment.unlocked = True
            assessment.locked_reason = None
        return assessment

    def build_chapter_assessment(
        self, chapter_id: str, unlocked: bool = False
    ) -> ChapterDidacticAssessment:
        """Alias for generate_assessment for pipeline ergonomics."""
        return self.generate_assessment(chapter_id=chapter_id, unlocked=unlocked)

    def get_assessment(
        self, chapter_id: str, unlocked: bool = False
    ) -> ChapterDidacticAssessment:
        """Alias for generate_assessment."""
        return self.generate_assessment(chapter_id=chapter_id, unlocked=unlocked)

    def generate_all_assessments(
        self, unlocked: bool = False
    ) -> Dict[str, ChapterDidacticAssessment]:
        """Return assessments for all 4 Halloween chapters keyed by chapter_id."""
        chapter_ids = [
            "sub_1_carving",
            "sub_2_candle_fsm",
            "sub_3_candy_saga",
            "sub_4_spooky_sync",
        ]
        return {
            cid: self.generate_assessment(cid, unlocked=unlocked) for cid in chapter_ids
        }

    # ------------------------------------------------------------------
    # FlipCard Answer Evaluation API
    # ------------------------------------------------------------------

    def evaluate_card_answer(
        self,
        request_or_chapter_id: Union[FlipCardAnswerRequest, str],
        maybe_request: Optional[FlipCardAnswerRequest] = None,
        *,
        chapter_id: Optional[str] = None,
        answered_cards: Optional[Dict[str, bool]] = None,
        total_cards_in_chapter: int = 4,
        feynman_score: Optional[int] = None,
        chapter_mastery_percentage: Optional[int] = None,
        overall_mastery_percentage: Optional[int] = None,
    ) -> FlipCardAnswerResponse:
        """Evaluate a FlipCardAnswerRequest.

        Supports calling styles:
        - evaluate_card_answer(request, chapter_mastery_percentage=..., overall_mastery_percentage=...)
        - evaluate_card_answer(chapter_id, request, ...)

        If knew_answer=False, returns a super intuitive Halloween child-friendly
        `simplified_metaphor` to reinforce Spiral ELI5 + Active Recall learning.
        """
        if isinstance(request_or_chapter_id, FlipCardAnswerRequest):
            request = request_or_chapter_id
            resolved_chapter_id = chapter_id or self._infer_chapter_id(request.card_id)
        else:
            resolved_chapter_id = request_or_chapter_id
            if maybe_request is None:
                raise ValueError(
                    "FlipCardAnswerRequest must be provided when chapter_id is passed first."
                )
            request = maybe_request

        if answered_cards is not None:
            answered_cards[request.card_id] = request.knew_answer

        if chapter_mastery_percentage is None:
            chapter_mastery_percentage = self._compute_chapter_mastery(
                answered_cards=answered_cards or {request.card_id: request.knew_answer},
                total_cards=total_cards_in_chapter,
                feynman_score=feynman_score,
            )

        if overall_mastery_percentage is None:
            overall_mastery_percentage = chapter_mastery_percentage

        if request.knew_answer:
            follow_up_message = (
                "🎃 Spooktacular recall! You nailed the architectural invariant—"
                "this pathway is locked into your mental model."
            )
            simplified_metaphor = None
        else:
            follow_up_message = (
                "👻 No worries! Let's dial down the complexity with a Halloween story "
                "metaphor before you flip the card again:"
            )
            simplified_metaphor = self.get_simplified_metaphor(
                card_id=request.card_id, chapter_id=resolved_chapter_id
            )

        return FlipCardAnswerResponse(
            card_id=request.card_id,
            knew_answer=request.knew_answer,
            follow_up_message=follow_up_message,
            simplified_metaphor=simplified_metaphor,
            chapter_mastery_percentage=chapter_mastery_percentage,
            overall_mastery_percentage=overall_mastery_percentage,
        )

    def evaluate_answer(
        self,
        request_or_chapter_id: Union[FlipCardAnswerRequest, str],
        maybe_request: Optional[FlipCardAnswerRequest] = None,
        **kwargs,
    ) -> FlipCardAnswerResponse:
        """Alias for evaluate_card_answer."""
        return self.evaluate_card_answer(
            request_or_chapter_id, maybe_request, **kwargs
        )

    def get_simplified_metaphor(
        self, card_id: str, chapter_id: Optional[str] = None
    ) -> str:
        """Return a child-friendly Halloween metaphor for a specific card or chapter."""
        if card_id in self._simplified_metaphors_by_card:
            return self._simplified_metaphors_by_card[card_id]
        inferred_chapter = chapter_id or self._infer_chapter_id(card_id)
        return self._chapter_fallback_metaphors.get(
            inferred_chapter,
            (
                "Imagine a team of friendly Halloween ghosts passing glowing lanterns "
                "one by one so nobody drops a pumpkin in the dark!"
            ),
        )

    # ------------------------------------------------------------------
    # Chapter 1: Autonomous Pumpkin Carving Worker Pool & Backpressure
    # ------------------------------------------------------------------

    def _build_sub_1_carving(self) -> ChapterDidacticAssessment:
        chapter_id = "sub_1_carving"
        file_path = "src/carving/dispatcher.py"

        flip_cards: List[FlipCard] = [
            FlipCard(
                card_id="sub_1_carving_card_1",
                chapter_id=chapter_id,
                front_question=(
                    "[Intent · EASY] Why does `PumpkinCarvingDispatcher.submit_job()` acquire "
                    "`self._worker_semaphore` BEFORE deserializing the 50MB 3D pumpkin voxel mesh?"
                ),
                socratic_hint=(
                    "Think about where the 50MB mesh lives in RAM while 10,000 coroutines "
                    "sit waiting at `await self._worker_semaphore.acquire()`."
                ),
                back_answer=(
                    "Acquiring the semaphore before hydrating the 3D voxel mesh keeps waiting jobs "
                    "as tiny 120-byte metadata tickets. If deserialization happened first, 10,000 "
                    "queued tasks would allocate ~500GB of heap memory and trigger an instant OOM kill."
                ),
                code_reference_file=file_path,
                code_reference_lines="L42-L56",
                code_snippet=(
                    "async def submit_job(self, ticket: CarveTicket) -> CarveResult:\n"
                    "    if self._queue_depth >= self.max_queue_depth:\n"
                    "        raise BackpressureShedError(retry_after_sec=2.0)\n"
                    "    async with self._worker_semaphore:  # Max 8 concurrent arms\n"
                    "        mesh = await self._mesh_loader.hydrate(ticket.pumpkin_id)\n"
                    "        return await self._carve_mesh(mesh, ticket.pattern)"
                ),
                difficulty="EASY",
                didactic_technique=DidacticTechnique.ACTIVE_RECALL_FLIPCARD,
            ),
            FlipCard(
                card_id="sub_1_carving_card_2",
                chapter_id=chapter_id,
                front_question=(
                    "[Data Trace · MEDIUM] Trace a `CarveTicket(pumpkin_id='jack-404')` arriving "
                    "when all 8 carving arms are busy and `_queue_depth == 64` (`max_queue_depth=64`). "
                    "What happens to the request and how does the upstream conveyor react?"
                ),
                socratic_hint=(
                    "Follow the guard clause at the top of `submit_job()` before the semaphore "
                    "context manager is ever entered."
                ),
                back_answer=(
                    "The dispatcher immediately fast-fails with `BackpressureShedError(retry_after_sec=2.0)` "
                    "(mapped to HTTP 429). The upstream conveyor pauses pulling from Kafka for 2 seconds "
                    "instead of piling up unbounded in-memory coroutines."
                ),
                code_reference_file=file_path,
                code_reference_lines="L38-L45",
                code_snippet=(
                    "if self._queue_depth >= self.max_queue_depth:\n"
                    "    metrics.increment('carving.backpressure_shed')\n"
                    "    raise BackpressureShedError(retry_after_sec=2.0)"
                ),
                difficulty="MEDIUM",
                didactic_technique=DidacticTechnique.SOCRATIC_MAIEUTICS,
            ),
            FlipCard(
                card_id="sub_1_carving_card_3",
                chapter_id=chapter_id,
                front_question=(
                    "[Counterfactual Bug · HARD] What happens to the 8-worker pool if "
                    "`self._worker_semaphore.release()` is called at the end of `try:` instead of "
                    "inside `finally:` when a tough pumpkin rind snaps a carving blade?"
                ),
                socratic_hint=(
                    "Count how many permits remain in `_worker_semaphore` after 8 pumpkins "
                    "raise `BladeJamException` over the course of an hour."
                ),
                back_answer=(
                    "Every `BladeJamException` skips `.release()`, permanently leaking one semaphore "
                    "permit. After 8 exceptions, available permits hit 0 and the entire carving "
                    "factory deadlocks forever with 0% CPU usage."
                ),
                code_reference_file=file_path,
                code_reference_lines="L60-L74",
                code_snippet=(
                    "await self._worker_semaphore.acquire()\n"
                    "try:\n"
                    "    return await self._robotic_arm.carve(mesh)\n"
                    "finally:\n"
                    "    self._worker_semaphore.release()  # Must NEVER be skipped!"
                ),
                difficulty="HARD",
                didactic_technique=DidacticTechnique.COUNTERFACTUAL_BREAK_IT,
            ),
            FlipCard(
                card_id="sub_1_carving_card_4",
                chapter_id=chapter_id,
                front_question=(
                    "[Production Trade-off · HARD] Why did we choose bounded in-memory queuing + "
                    "HTTP 429 shedding over spilling excess 3D pumpkin meshes to local NVMe disk?"
                ),
                socratic_hint=(
                    "Consider tail latency (P99) and disk I/O contention when carving has a strict "
                    "real-time 800ms SLA before the pumpkin rolls past the laser station."
                ),
                back_answer=(
                    "Spilling 50MB voxel meshes to disk saturates NVMe IOPS and inflates queue wait "
                    "times past the 800ms physical conveyor SLA—meaning we would waste compute carving "
                    "pumpkins that already rolled past the station. Fast 429 shedding preserves low "
                    "P99 latency for accepted pumpkins."
                ),
                code_reference_file=file_path,
                code_reference_lines="L18-L35",
                code_snippet=(
                    "MAX_CONCURRENT_ARMS = 8\n"
                    "MAX_QUEUE_DEPTH = 64  # Bounded to guarantee P99 < 800ms conveyor SLA\n"
                    "CONVEYOR_SLA_TIMEOUT_SEC = 0.8"
                ),
                difficulty="HARD",
                didactic_technique=DidacticTechnique.SPIRAL_ELI5,
            ),
        ]

        # Shuffled order for Parsons puzzle (correct_order_index: 0, 1, 2, 3)
        parsons_blocks_shuffled: List[ParsonsBlock] = [
            ParsonsBlock(
                block_id="sub_1_block_3",
                correct_order_index=2,
                label="Hydrate 3D voxel mesh & execute robotic carving path",
                code_line="mesh = await self._mesh_loader.hydrate(ticket.pumpkin_id); return await self._carve_mesh(mesh)",
            ),
            ParsonsBlock(
                block_id="sub_1_block_1",
                correct_order_index=0,
                label="Reject overflow traffic immediately when bounded queue is full",
                code_line="if self._queue_depth >= self.max_queue_depth: raise BackpressureShedError(retry_after_sec=2.0)",
            ),
            ParsonsBlock(
                block_id="sub_1_block_4",
                correct_order_index=3,
                label="Guarantee semaphore permit release even on BladeJamException",
                code_line="finally: self._worker_semaphore.release(); self._queue_depth -= 1",
            ),
            ParsonsBlock(
                block_id="sub_1_block_2",
                correct_order_index=1,
                label="Acquire bounded worker permit before allocating heavy mesh memory",
                code_line="self._queue_depth += 1; await self._worker_semaphore.acquire()",
            ),
        ]

        return ChapterDidacticAssessment(
            chapter_id=chapter_id,
            unlocked=False,
            locked_reason=LOCKED_ASSESSMENT_REASON,
            socratic_opening_question=(
                "Before flipping the cards: If 10,000 raw pumpkins roll down the haunted chute "
                "at midnight while only 8 robotic carving arms exist, why does an unbounded "
                "`asyncio.gather()` crash the factory floor instead of carving faster?"
            ),
            flip_cards=flip_cards,
            parsons_blocks_shuffled=parsons_blocks_shuffled,
            feynman_prompt=(
                "Explain to the Ghostly Rubber Duck how our Pumpkin Carving Dispatcher prevents "
                "Out-Of-Memory crashes during a 10,000-pumpkin Halloween spike, and why the "
                "`finally` block is critical when a carving blade jams."
            ),
            required_concepts_for_feynman=[
                "backpressure",
                "semaphore",
                "bounded queue",
                "finally",
            ],
        )

    # ------------------------------------------------------------------
    # Chapter 2: Jack-O'-Lantern Ignition FSM & Wind Gust Recovery
    # ------------------------------------------------------------------

    def _build_sub_2_candle_fsm(self) -> ChapterDidacticAssessment:
        chapter_id = "sub_2_candle_fsm"
        file_path = "src/lighting/candle_fsm.py"

        flip_cards: List[FlipCard] = [
            FlipCard(
                card_id="sub_2_candle_fsm_card_1",
                chapter_id=chapter_id,
                front_question=(
                    "[Intent · EASY] Why does `CandleStateMachine.transition(target)` validate "
                    "`target in ALLOWED_TRANSITIONS[self.state]` inside an `asyncio.Lock` instead "
                    "of mutating `self.state` directly?"
                ),
                socratic_hint=(
                    "What happens if a wind-gust sensor coroutine and a manual igniter coroutine "
                    "both read `self.state == EXTINGUISHED` on the same event-loop tick?"
                ),
                back_answer=(
                    "The lock + transition table serialize concurrent sensor events and enforce "
                    "physical invariants (e.g., a candle cannot jump from `EXTINGUISHED` straight "
                    "to `LIT` without `SPARKING`, nor can `SPARKING` re-enter `SPARKING`)."
                ),
                code_reference_file=file_path,
                code_reference_lines="L29-L48",
                code_snippet=(
                    "async def transition(self, target: CandleState) -> CandleState:\n"
                    "    async with self._state_lock:\n"
                    "        if target not in ALLOWED_TRANSITIONS[self.state]:\n"
                    "            raise InvalidStateTransitionError(self.state, target)\n"
                    "        self.state = target\n"
                    "        return self.state"
                ),
                difficulty="EASY",
                didactic_technique=DidacticTechnique.ACTIVE_RECALL_FLIPCARD,
            ),
            FlipCard(
                card_id="sub_2_candle_fsm_card_2",
                chapter_id=chapter_id,
                front_question=(
                    "[Data Trace · MEDIUM] Trace a `LIT` pumpkin when a graveyard gale triggers "
                    "`on_wind_gust()` and the piezo igniter fails on attempt #1. Through which exact "
                    "sequence of states does the FSM travel before sparking again?"
                ),
                socratic_hint=(
                    "Check why `EXTINGUISHED` cannot loop back to `SPARKING` after a failed spark "
                    "without venting buildup gas first."
                ),
                back_answer=(
                    "It transitions `LIT -> FLICKERING -> EXTINGUISHED -> SPARKING` (attempt #1 fails) "
                    "`-> COOLDOWN -> EXTINGUISHED -> SPARKING`. The mandatory `COOLDOWN` state vents "
                    "unburned wax vapor before another piezo spark is allowed."
                ),
                code_reference_file=file_path,
                code_reference_lines="L52-L71",
                code_snippet=(
                    "ALLOWED_TRANSITIONS = {\n"
                    "    CandleState.UNLIT: {CandleState.SPARKING},\n"
                    "    CandleState.SPARKING: {CandleState.LIT, CandleState.COOLDOWN},\n"
                    "    CandleState.LIT: {CandleState.FLICKERING, CandleState.EXTINGUISHED},\n"
                    "    CandleState.FLICKERING: {CandleState.LIT, CandleState.EXTINGUISHED},\n"
                    "    CandleState.EXTINGUISHED: {CandleState.SPARKING, CandleState.COOLDOWN},\n"
                    "    CandleState.COOLDOWN: {CandleState.EXTINGUISHED},\n"
                    "}"
                ),
                difficulty="MEDIUM",
                didactic_technique=DidacticTechnique.SOCRATIC_MAIEUTICS,
            ),
            FlipCard(
                card_id="sub_2_candle_fsm_card_3",
                chapter_id=chapter_id,
                front_question=(
                    "[Counterfactual Bug · HARD] What physical and software failure occurs if we "
                    "permit `CandleState.SPARKING -> CandleState.SPARKING` idempotently without "
                    "rejecting duplicate spark commands?"
                ),
                socratic_hint=(
                    "Remember that `SPARKING` opens the methane micro-valve for 400ms while the "
                    "piezo arc charges."
                ),
                back_answer=(
                    "Two overlapping `SPARKING` entries open the fuel valve twice before the first "
                    "arc fires, doubling methane concentration inside the pumpkin shell and causing "
                    "a literal Jack-O'-Lantern blowout (plus orphaned timer tasks)."
                ),
                code_reference_file=file_path,
                code_reference_lines="L74-L89",
                code_snippet=(
                    "if self.state == CandleState.SPARKING:\n"
                    "    raise InvalidStateTransitionError(\n"
                    "        'Double-spark blocked: piezo igniter already active!'\n"
                    "    )"
                ),
                difficulty="HARD",
                didactic_technique=DidacticTechnique.COUNTERFACTUAL_BREAK_IT,
            ),
            FlipCard(
                card_id="sub_2_candle_fsm_card_4",
                chapter_id=chapter_id,
                front_question=(
                    "[Production Trade-off · HARD] Why does `_compute_relight_delay(attempt)` use "
                    "exponential backoff with full jitter (`random.uniform(0, cap)`) instead of a "
                    "deterministic `2 ** attempt` delay?"
                ),
                socratic_hint=(
                    "A single gust of wind blows out all 500 cemetery pumpkins at the exact same "
                    "millisecond (`t = 0.000s`). When would deterministic backoff fire attempt #1, #2, #3?"
                ),
                back_answer=(
                    "Without jitter, all 500 pumpkins wake up in lockstep at `t=2s`, `t=4s`, and `t=8s`, "
                    "creating a synchronized thundering-herd current spike that trips the cemetery "
                    "breaker. Full jitter spreads relight sparks smoothly across the entire window."
                ),
                code_reference_file=file_path,
                code_reference_lines="L92-L103",
                code_snippet=(
                    "def _compute_relight_delay(self, attempt: int) -> float:\n"
                    "    ceiling = min(self.max_backoff_sec, self.base_delay_sec * (2 ** attempt))\n"
                    "    return random.uniform(0.1, ceiling)  # Full jitter prevents synchronized surge"
                ),
                difficulty="HARD",
                didactic_technique=DidacticTechnique.SPIRAL_ELI5,
            ),
        ]

        parsons_blocks_shuffled: List[ParsonsBlock] = [
            ParsonsBlock(
                block_id="sub_2_block_3",
                correct_order_index=2,
                label="On spark failure, enter COOLDOWN and sleep with full-jitter backoff",
                code_line="await self.transition(CandleState.COOLDOWN); await asyncio.sleep(self._compute_relight_delay(attempt))",
            ),
            ParsonsBlock(
                block_id="sub_2_block_1",
                correct_order_index=0,
                label="Acquire state lock and transition extinguished candle to SPARKING",
                code_line="await self.transition(CandleState.SPARKING)  # Acquires _state_lock & checks ALLOWED_TRANSITIONS",
            ),
            ParsonsBlock(
                block_id="sub_2_block_4",
                correct_order_index=3,
                label="Exit cooldown back to EXTINGUISHED so the next retry can cleanly spark",
                code_line="await self.transition(CandleState.EXTINGUISHED)",
            ),
            ParsonsBlock(
                block_id="sub_2_block_2",
                correct_order_index=1,
                label="Fire piezo igniter pulse and transition to LIT if flame sensor confirms",
                code_line="if await self._igniter.pulse_and_verify(): return await self.transition(CandleState.LIT)",
            ),
        ]

        return ChapterDidacticAssessment(
            chapter_id=chapter_id,
            unlocked=False,
            locked_reason=LOCKED_ASSESSMENT_REASON,
            socratic_opening_question=(
                "Before flipping the cards: If a sudden graveyard wind gust blows out 500 "
                "Jack-O'-Lanterns at the exact same millisecond, why would an immediate retry "
                "loop burn down the power grid—and why must `SPARKING` never transition directly "
                "to `SPARKING`?"
            ),
            flip_cards=flip_cards,
            parsons_blocks_shuffled=parsons_blocks_shuffled,
            feynman_prompt=(
                "Explain to the Ghostly Rubber Duck how our Candle Finite State Machine prevents "
                "double-spark explosions and stops all 500 candles from overloading the power "
                "grid when relighting after a wind gust."
            ),
            required_concepts_for_feynman=[
                "state machine",
                "transition guard",
                "cooldown",
                "jitter",
            ],
        )

    # ------------------------------------------------------------------
    # Chapter 3: Distributed Trick-or-Treat Candy Escrow Saga
    # ------------------------------------------------------------------

    def _build_sub_3_candy_saga(self) -> ChapterDidacticAssessment:
        chapter_id = "sub_3_candy_saga"
        file_path = "src/commerce/candy_saga.py"

        flip_cards: List[FlipCard] = [
            FlipCard(
                card_id="sub_3_candy_saga_card_1",
                chapter_id=chapter_id,
                front_question=(
                    "[Intent · EASY] Why does `CandySagaOrchestrator.execute()` push a compensating "
                    "handler onto `compensation_stack` immediately after each forward microservice "
                    "step succeeds?"
                ),
                socratic_hint=(
                    "Can `CandyVaultService`, `GhostCourierService`, and `KidBucketLedger` share a "
                    "single PostgreSQL `ROLLBACK` across three separate databases?"
                ),
                back_answer=(
                    "Because each microservice commits its local transaction immediately, there is "
                    "no global ACID rollback. Recording each step's inverse action on a LIFO stack "
                    "lets the orchestrator undo only the steps that actually succeeded if a later "
                    "step fails."
                ),
                code_reference_file=file_path,
                code_reference_lines="L34-L55",
                code_snippet=(
                    "compensation_stack: List[Callable[[], Awaitable[None]]] = []\n"
                    "await self.vault.reserve_candy(tx_id, sku, qty)\n"
                    "compensation_stack.append(lambda: self.vault.release_candy(tx_id))\n"
                    "await self.courier.dispatch_broomstick(tx_id, kid_address)\n"
                    "compensation_stack.append(lambda: self.courier.recall_broomstick(tx_id))"
                ),
                difficulty="EASY",
                didactic_technique=DidacticTechnique.ACTIVE_RECALL_FLIPCARD,
            ),
            FlipCard(
                card_id="sub_3_candy_saga_card_2",
                chapter_id=chapter_id,
                front_question=(
                    "[Data Trace · MEDIUM] Suppose Step 1 (`reserve_candy`) and Step 2 "
                    "(`dispatch_broomstick`) succeed, but Step 3 (`credit_kid_bucket`) raises "
                    "`BucketFullError`. In what exact order do the compensating transactions run?"
                ),
                socratic_hint=(
                    "Look at `for compensate in reversed(compensation_stack):` in the exception "
                    "handler."
                ),
                back_answer=(
                    "Compensations run in strict reverse (LIFO) order: first "
                    "`courier.recall_broomstick(tx_id)` cancels the in-flight delivery, and second "
                    "`vault.release_candy(tx_id)` unlocks the reserved chocolate bars back into inventory."
                ),
                code_reference_file=file_path,
                code_reference_lines="L56-L70",
                code_snippet=(
                    "except Exception as saga_err:\n"
                    "    for compensate in reversed(compensation_stack):\n"
                    "        await self._run_with_retry(compensate)\n"
                    "    raise SagaRolledBackError(tx_id) from saga_err"
                ),
                difficulty="MEDIUM",
                didactic_technique=DidacticTechnique.SOCRATIC_MAIEUTICS,
            ),
            FlipCard(
                card_id="sub_3_candy_saga_card_3",
                chapter_id=chapter_id,
                front_question=(
                    "[Counterfactual Bug · HARD] What happens if `vault.release_candy(tx_id)` adds "
                    "`+qty` back to inventory without checking if `tx_id` was already refunded, and "
                    "a network timeout triggers a compensation retry?"
                ),
                socratic_hint=(
                    "If the first `release_candy(tx_id)` succeeded on the Vault DB but its HTTP 200 "
                    "response dropped in flight, what does `_run_with_retry` do next?"
                ),
                back_answer=(
                    "The retry executes `release_candy(tx_id)` a second time, crediting `+qty` twice "
                    "and creating phantom candy inventory out of thin air! Every saga step and "
                    "compensation MUST be idempotent keyed by `tx_id`."
                ),
                code_reference_file=file_path,
                code_reference_lines="L75-L92",
                code_snippet=(
                    "async def release_candy(self, tx_id: UUID) -> None:\n"
                    "    if await self.ledger.is_already_compensated(tx_id):\n"
                    "        return  # Idempotent no-op on retry\n"
                    "    await self.ledger.mark_compensated_and_restore_stock(tx_id)"
                ),
                difficulty="HARD",
                didactic_technique=DidacticTechnique.COUNTERFACTUAL_BREAK_IT,
            ),
            FlipCard(
                card_id="sub_3_candy_saga_card_4",
                chapter_id=chapter_id,
                front_question=(
                    "[Production Trade-off · HARD] Why did we architect Candy Checkout as an "
                    "asynchronous Saga instead of Two-Phase Commit (2PC / XA distributed locks) "
                    "across the Vault, Courier, and Bucket databases?"
                ),
                socratic_hint=(
                    "How long does a Ghost Courier dispatch check take compared to a database row "
                    "lock when 50,000 kids knock on doors simultaneously?"
                ),
                back_answer=(
                    "2PC holds row-level locks across all participating nodes until the slowest "
                    "participant prepares—turning a slow Courier RPC into a total Candy Vault "
                    "deadlock. A Saga releases local DB locks immediately at the cost of eventual "
                    "consistency (briefly reserved stock during rollback)."
                ),
                code_reference_file=file_path,
                code_reference_lines="L12-L28",
                code_snippet=(
                    "# Saga Pattern: Local ACID transactions + idempotent LIFO compensations.\n"
                    "# Avoids cross-service 2PC lock contention during Halloween peak traffic."
                ),
                difficulty="HARD",
                didactic_technique=DidacticTechnique.SPIRAL_ELI5,
            ),
        ]

        parsons_blocks_shuffled: List[ParsonsBlock] = [
            ParsonsBlock(
                block_id="sub_3_block_3",
                correct_order_index=2,
                label="Attempt Step 3 (credit kid's candy bucket) which may raise BucketFullError",
                code_line="await self.bucket_ledger.credit_kid_bucket(tx_id, kid_id, qty)",
            ),
            ParsonsBlock(
                block_id="sub_3_block_1",
                correct_order_index=0,
                label="Reserve candy in Vault with idempotency key and push compensation",
                code_line="await self.vault.reserve_candy(tx_id, sku, qty); compensation_stack.append(lambda: self.vault.release_candy(tx_id))",
            ),
            ParsonsBlock(
                block_id="sub_3_block_4",
                correct_order_index=3,
                label="On failure, unwind completed steps in reverse LIFO order with idempotent retries",
                code_line="except Exception: [await self._retry_idempotent(c) for c in reversed(compensation_stack)]; raise",
            ),
            ParsonsBlock(
                block_id="sub_3_block_2",
                correct_order_index=1,
                label="Dispatch ghost courier broomstick and push recall compensation",
                code_line="await self.courier.dispatch_broomstick(tx_id, addr); compensation_stack.append(lambda: self.courier.recall_broomstick(tx_id))",
            ),
        ]

        return ChapterDidacticAssessment(
            chapter_id=chapter_id,
            unlocked=False,
            locked_reason=LOCKED_ASSESSMENT_REASON,
            socratic_opening_question=(
                "Before flipping the cards: Since `CandyVaultDB` and `GhostCourierService` live "
                "on separate haunted servers without a shared SQL transaction, how do we stop "
                "candy from vanishing into limbo when a delivery broomstick crashes mid-flight?"
            ),
            flip_cards=flip_cards,
            parsons_blocks_shuffled=parsons_blocks_shuffled,
            feynman_prompt=(
                "Explain to the Ghostly Rubber Duck how the Candy Saga guarantees no chocolate "
                "bars are lost or double-refunded when a delivery broomstick crashes halfway "
                "through a distributed transaction."
            ),
            required_concepts_for_feynman=[
                "saga",
                "compensating transaction",
                "rollback",
                "idempotency",
            ],
        )

    # ------------------------------------------------------------------
    # Chapter 4: 500-Skeleton Dancers Distributed Clock Sync & Barrier
    # ------------------------------------------------------------------

    def _build_sub_4_spooky_sync(self) -> ChapterDidacticAssessment:
        chapter_id = "sub_4_spooky_sync"
        file_path = "src/chorus/spooky_sync.py"

        flip_cards: List[FlipCard] = [
            FlipCard(
                card_id="sub_4_spooky_sync_card_1",
                chapter_id=chapter_id,
                front_question=(
                    "[Intent · EASY] Why does `SkeletonChoreographer` compute each dance beat "
                    "deadline using `time.monotonic() + self.clock_offset_ms` instead of "
                    "`datetime.now()`?"
                ),
                socratic_hint=(
                    "What happens to `datetime.now()` if a background OS daemon runs an NTP step "
                    "adjustment right in the middle of a skeleton backflip?"
                ),
                back_answer=(
                    "`datetime.now()` (wall-clock time) can jump backward or forward when the OS "
                    "corrects NTP drift, causing skeletons to freeze or replay keyframes twice. "
                    "`time.monotonic()` guarantees a strictly forward-marching hardware tick rate, "
                    "onto which we layer our smoothed Maestro offset."
                ),
                code_reference_file=file_path,
                code_reference_lines="L24-L39",
                code_snippet=(
                    "def maestro_now_ms(self) -> float:\n"
                    "    local_mono_ms = time.monotonic() * 1000.0\n"
                    "    return local_mono_ms + self._smoothed_offset_ms"
                ),
                difficulty="EASY",
                didactic_technique=DidacticTechnique.ACTIVE_RECALL_FLIPCARD,
            ),
            FlipCard(
                card_id="sub_4_spooky_sync_card_2",
                chapter_id=chapter_id,
                front_question=(
                    "[Data Trace · MEDIUM] Trace `estimate_offset(t1, t2, t3, t4)` when a Wi-Fi "
                    "interference spike causes round-trip time `rtt = (t4 - t1) - (t3 - t2)` to hit "
                    "`145ms` (`MAX_ACCEPTABLE_RTT_MS = 40ms`). How is `_smoothed_offset_ms` updated?"
                ),
                socratic_hint=(
                    "Asymmetric Wi-Fi queueing delay corrupts the `((t2 - t1) + (t3 - t4)) / 2` "
                    "symmetry assumption. Check the outlier filter."
                ),
                back_answer=(
                    "The sample is rejected as a high-jitter outlier and `_smoothed_offset_ms` "
                    "remains unchanged (coast mode on local monotonic clock). Accepting a 145ms "
                    "asymmetric Wi-Fi spike would yank the skeleton's phase by up to ~70ms."
                ),
                code_reference_file=file_path,
                code_reference_lines="L44-L62",
                code_snippet=(
                    "rtt_ms = (t4 - t1) - (t3 - t2)\n"
                    "if rtt_ms > MAX_ACCEPTABLE_RTT_MS:\n"
                    "    metrics.increment('sync.outlier_discarded')\n"
                    "    return self._smoothed_offset_ms  # Coast on monotonic clock"
                ),
                difficulty="MEDIUM",
                didactic_technique=DidacticTechnique.SOCRATIC_MAIEUTICS,
            ),
            FlipCard(
                card_id="sub_4_spooky_sync_card_3",
                chapter_id=chapter_id,
                front_question=(
                    "[Counterfactual Bug · HARD] What happens to all 500 skeletons on stage if "
                    "`FrameBarrier.wait_for_beat(beat_id)` uses `await self._barrier.wait()` "
                    "WITHOUT `asyncio.wait_for(..., timeout=0.016)` when Skeleton #13's battery dies?"
                ),
                socratic_hint=(
                    "A classic barrier waits until all `N = 500` participants arrive before "
                    "releasing any participant."
                ),
                back_answer=(
                    "499 healthy skeletons block forever waiting for Skeleton #13's ACK packet, "
                    "turning a single dead battery into a 100% stage freeze! A bounded 16ms frame "
                    "timeout lets the quorum of 499 skeletons advance on the beat."
                ),
                code_reference_file=file_path,
                code_reference_lines="L68-L84",
                code_snippet=(
                    "try:\n"
                    "    await asyncio.wait_for(self._barrier.wait(), timeout=FRAME_BUDGET_SEC)\n"
                    "except asyncio.TimeoutError:\n"
                    "    self._evict_lagging_skeletons(beat_id)  # Keep the show moving!"
                ),
                difficulty="HARD",
                didactic_technique=DidacticTechnique.COUNTERFACTUAL_BREAK_IT,
            ),
            FlipCard(
                card_id="sub_4_spooky_sync_card_4",
                chapter_id=chapter_id,
                front_question=(
                    "[Production Trade-off · HARD] When a skeleton recovers from a 200ms Wi-Fi drop "
                    "(12 frames behind), why does it drop missed frames and snap to `current_beat_id` "
                    "instead of playing the 12 missed frames at 2x speed?"
                ),
                socratic_hint=(
                    "In a 500-dancer chorus line, what does the human eye notice more: one skeleton "
                    "skipping a transition or one skeleton dancing out-of-phase for 600ms?"
                ),
                back_answer=(
                    "Playing buffered frames at 2x speed keeps the skeleton visibly out-of-phase "
                    "with its 499 neighbors for hundreds of milliseconds and saturates servo torque "
                    "limits. Dropping stale frames and phase-locking to the next beat restores "
                    "visual ensemble harmony within a single 16.6ms frame."
                ),
                code_reference_file=file_path,
                code_reference_lines="L88-L104",
                code_snippet=(
                    "if target_beat_id < maestro_current_beat:\n"
                    "    metrics.increment('sync.late_frames_dropped',\n"
                    "                      maestro_current_beat - target_beat_id)\n"
                    "    return self._interpolate_to_beat(maestro_current_beat)"
                ),
                difficulty="HARD",
                didactic_technique=DidacticTechnique.SPIRAL_ELI5,
            ),
        ]

        parsons_blocks_shuffled: List[ParsonsBlock] = [
            ParsonsBlock(
                block_id="sub_4_block_3",
                correct_order_index=2,
                label="Await frame barrier with strict 16ms timeout so one dead skeleton never stalls the show",
                code_line="await asyncio.wait_for(self._barrier.wait(), timeout=0.016)",
            ),
            ParsonsBlock(
                block_id="sub_4_block_1",
                correct_order_index=0,
                label="Filter out high-RTT Wi-Fi jitter spikes before updating smoothed clock offset",
                code_line="if (t4 - t1) - (t3 - t2) <= MAX_RTT_MS: self._update_offset(((t2 - t1) + (t3 - t4)) / 2)",
            ),
            ParsonsBlock(
                block_id="sub_4_block_4",
                correct_order_index=3,
                label="Drop stale frames if behind Maestro and render current beat keyframe",
                code_line="beat_id = max(local_beat_id, maestro_beat_id); self._render_pose(beat_id)",
            ),
            ParsonsBlock(
                block_id="sub_4_block_2",
                correct_order_index=1,
                label="Compute synchronized Maestro timestamp using monotonic clock plus smoothed offset",
                code_line="synced_now_ms = (time.monotonic() * 1000.0) + self._smoothed_offset_ms",
            ),
        ]

        return ChapterDidacticAssessment(
            chapter_id=chapter_id,
            unlocked=False,
            locked_reason=LOCKED_ASSESSMENT_REASON,
            socratic_opening_question=(
                "Before flipping the cards: If Skeleton #42's ribcage CPU clock runs 80ms slower "
                "than the Maestro's baton, and Wi-Fi packets jitter between 5ms and 120ms, how "
                "can 500 skeletons snap their fingers on the exact same video frame without "
                "freezing the show?"
            ),
            flip_cards=flip_cards,
            parsons_blocks_shuffled=parsons_blocks_shuffled,
            feynman_prompt=(
                "Explain to the Ghostly Rubber Duck how 500 wireless skeletons stay synchronized "
                "on the same dance beat despite clock drift, network jitter, and occasional "
                "Wi-Fi dropouts."
            ),
            required_concepts_for_feynman=[
                "clock drift",
                "monotonic",
                "barrier",
                "timeout",
            ],
        )

    # ------------------------------------------------------------------
    # Internal Helpers & Child-Friendly Metaphors per Card
    # ------------------------------------------------------------------

    def _build_card_metaphors(self) -> Dict[str, str]:
        """Child-friendly Halloween metaphors returned when knew_answer=False."""
        return {
            # Chapter 1: Pumpkin Carving
            "sub_1_carving_card_1": (
                "🎃 Imagine 10,000 kids waiting outside a Haunted Art Room with only 8 tables. "
                "Instead of carrying heavy 50-pound giant pumpkins in their arms while standing "
                "in line (which would make everyone collapse!), each kid holds a tiny paper "
                "ticket and only grabs a heavy pumpkin AFTER they get a table!"
            ),
            "sub_1_carving_card_2": (
                "🧛 Think of Friendly Count Bouncer standing at the porch steps! When all 8 "
                "carving tables are busy AND 64 pumpkins are already waiting on the porch bench, "
                "he holds up a glowing 'Come Back in 2 Seconds!' sign so the porch never caves in."
            ),
            "sub_1_carving_card_3": (
                "🔑 Imagine there are only 8 magic keys to the carving kitchen. If a monster chef "
                "breaks a plastic knife and storms out the back door WITHOUT putting their key "
                "back on the hook (`finally:`), after 8 broken knives zero keys are left and "
                "nobody can ever enter the kitchen again!"
            ),
            "sub_1_carving_card_4": (
                "🛷 Pumpkins ride past the carving robot on a fast spooky roller-coaster! If we "
                "stuffed extra pumpkins into a dusty basement closet (disk) and dug them out "
                "later, their roller-coaster cart would already be gone! Saying 'Wait 2 seconds' "
                "at the gate keeps every accepted pumpkin right on time."
            ),
            # Chapter 2: Candle FSM
            "sub_2_candle_fsm_card_1": (
                "🕯️ Imagine a Jack-O'-Lantern has a strict rulebook with a padlock: it can only "
                "go from Dark -> Sparking -> Glowing. The padlock makes sure two ghosts can't "
                "flip the switch at the exact same moment and confuse the candle!"
            ),
            "sub_2_candle_fsm_card_2": (
                "💨 When a spooky wind blows out a candle and the first match fizzles out, the "
                "pumpkin is filled with smoky match gas. It MUST take a short 'Cool-Down Breath' "
                "(`COOLDOWN`) to let the smoke out before striking another match!"
            ),
            "sub_2_candle_fsm_card_3": (
                "💥 Striking two matches inside the same pumpkin at the same time squirts double "
                "the lighter fluid before the flame catches—KABOOM! Blocking `SPARKING -> SPARKING` "
                "stops the pumpkin from blowing its own lid off."
            ),
            "sub_2_candle_fsm_card_4": (
                "🎲 If 500 kids all try to run through one narrow haunted doorway at the exact "
                "same second, they get stuck! So each pumpkin rolls a magic dice (`jitter`) and "
                "waits a slightly different number of milliseconds before relighting."
            ),
            # Chapter 3: Candy Saga
            "sub_3_candy_saga_card_1": (
                "📜 Imagine a Ghost Postmaster writing down each step in a magic notebook with "
                "an 'Undo Spell' next to it: Step 1 Lock Candy (Undo: Unlock Candy), Step 2 "
                "Launch Broomstick (Undo: Whistle Broomstick Back). That way, if Step 3 fails, "
                "he knows exactly how to rewind!"
            ),
            "sub_3_candy_saga_card_2": (
                "⏪ Just like taking off your Halloween costume at night—you have to take off "
                "your witch hat BEFORE you pull your sweater over your head! The Saga undoes "
                "the last step first (call back the broomstick, THEN put the candy back in the vault)."
            ),
            "sub_3_candy_saga_card_3": (
                "🍫 Imagine a kid says 'My delivery failed, give me my chocolate back!' and "
                "because of a noisy ghost walkie-talkie, says it twice. By stamping a unique "
                "Ticket Number (`tx_id`) in the book, the Vault Ghost checks the stamp and "
                "never hands out double refund candy!"
            ),
            "sub_3_candy_saga_card_4": (
                "🏰 Two-Phase Commit (2PC) is like locking the entire Candy Castle doors while "
                "waiting for one slow broomstick to fly across town—nobody else can buy candy! "
                "A Saga lets the castle doors stay open and just puts a sticky-note on your "
                "candy bar while the broomstick flies."
            ),
            # Chapter 4: Spooky Sync
            "sub_4_spooky_sync_card_1": (
                "⏱️ A wall clock can jump backward by an hour on Daylight Saving night, which "
                "would confuse a dancing skeleton! Instead, each skeleton counts steady heartbeats "
                "on a stopwatch (`monotonic`) that only ever ticks forward."
            ),
            "sub_4_spooky_sync_card_2": (
                "🦇 If the Maestro shouts 'Sync watches!' and the messenger bat gets stuck in "
                "a spiderweb for 145ms on the way there, that message is stale! The skeleton "
                "ignores the late bat and keeps trusting its steady stopwatch."
            ),
            "sub_4_spooky_sync_card_3": (
                "💀 Imagine 500 skeletons holding hands waiting for Skeleton #13 to tie his "
                "shoelace before anyone takes the next dance step. With a 16-millisecond "
                "timer (`timeout`), the 499 skeletons say 'Catch up on the next beat!' and "
                "keep the dance show rolling."
            ),
            "sub_4_spooky_sync_card_4": (
                "🕺 If a dancer trips for a moment during the Monster Mash, they don't do "
                "12 frantic fast-forward moves while everyone else is clapping—they skip straight "
                "to the current clap so the whole stage looks in sync right away!"
            ),
        }

    @staticmethod
    def _infer_chapter_id(card_id: str) -> str:
        for prefix in (
            "sub_1_carving",
            "sub_2_candle_fsm",
            "sub_3_candy_saga",
            "sub_4_spooky_sync",
        ):
            if card_id.startswith(prefix):
                return prefix
        return "sub_1_carving"

    @staticmethod
    def _compute_chapter_mastery(
        answered_cards: Dict[str, bool],
        total_cards: int = 4,
        feynman_score: Optional[int] = None,
    ) -> int:
        """Compute chapter mastery percentage (60% weight on cards, 40% on Feynman voice)."""
        if total_cards <= 0:
            total_cards = 4
        knew_count = sum(1 for knew in answered_cards.values() if knew)
        card_ratio = min(1.0, knew_count / float(total_cards))
        if feynman_score is None:
            return int(round(card_ratio * 60.0))
        return min(100, int(round(card_ratio * 60.0 + (feynman_score / 100.0) * 40.0)))
