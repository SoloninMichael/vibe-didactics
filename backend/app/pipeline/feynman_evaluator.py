"""Feynman Rubber Duck Multimodal Voice & Code Comprehension Evaluator.

Simulates the 'Explain to the Spooky Rubber Duck' (Professor Quackenstein,
The Junior Rubber Duck) voice comprehension checker. Evaluates transcribed
developer explanations against each chapter's `required_concepts_for_feynman`
using case-insensitive semantic concept and synonym matching.
"""

from __future__ import annotations

import re
from typing import Dict, List, Optional, Sequence, Set, Tuple, Union

from app.schemas import (
    DidacticChapter,
    FeynmanVoiceFeedback,
    FeynmanVoiceRequest,
)


class FeynmanVoiceEvaluator:
    """Evaluates spoken Feynman explanations for Professor Quackenstein (The Junior Rubber Duck)."""

    PASSING_SCORE_THRESHOLD: int = 70
    DUCK_PERSONA_NAME: str = "Professor Quackenstein (The Junior Rubber Duck)"

    # Direct & fine-grained synonym lookup keyed by normalized concept name.
    # Each entry contains (primary_synonyms, family_fallback_synonyms).
    # `family_fallback_synonyms` are used when no sibling required concept in the same
    # chapter already claims that keyword as its own primary concept.
    _CONCEPT_SYNONYMS: Dict[str, Tuple[Tuple[str, ...], Tuple[str, ...]]] = {
        # --- Chapter 1: Pumpkin Carving (Idempotency / Duplicate / Lock / Backpressure) ---
        "idempotency": (
            (
                "idempoten",
                "idempotency_key",
                "idempotent",
                "dedup",
                "exactly-once",
                "at-most-once",
                "same key",
                "same request",
                "already processed",
                "already carved",
                "cached result",
                "short-circuit",
                "ledger",
            ),
            (
                "duplicate",
                "double",
                "twice",
                "repeat",
                "retry",
                "retries",
                "lock",
                "version",
                "expected_version",
                "cas",
                "compare-and-swap",
            ),
        ),
        "idempotency_key": (
            (
                "idempotency_key",
                "idempoten",
                "dedup",
                "ticket",
                "unique key",
                "request key",
                "ledger",
                "cached",
            ),
            ("duplicate", "double", "twice", "retry", "lock"),
        ),
        "duplicate": (
            (
                "duplicate",
                "dedup",
                "double",
                "twice",
                "repeat",
                "re-carv",
                "multiple times",
                "second time",
                "redundant",
                "webhook retry",
            ),
            ("idempoten", "retry", "retries", "same request"),
        ),
        "lock": (
            (
                "lock",
                "mutex",
                "semaphore",
                "acquire",
                "exclusive",
                "concurrent",
                "concurrency",
                "race condition",
                "atomic",
                "set nx",
                "bouncer",
                "fencing",
            ),
            ("ttl", "lease", "release", "serializ", "idempoten"),
        ),
        "distributed lock": (
            (
                "distributed lock",
                "lock",
                "mutex",
                "semaphore",
                "acquire",
                "redis",
                "set nx",
                "exclusive",
                "race condition",
                "concurrent",
                "bouncer",
            ),
            ("ttl", "lease", "fencing", "atomic"),
        ),
        "backpressure": (
            (
                "backpressure",
                "back-pressure",
                "shed",
                "load shedding",
                "429",
                "rate limit",
                "token bucket",
                "throttle",
                "overload",
                "overflow",
                "reject",
                "fast-fail",
            ),
            ("duplicate", "dedup", "drop", "bounded", "queue", "memory", "oom"),
        ),
        "semaphore": (
            (
                "semaphore",
                "worker_semaphore",
                "permit",
                "concurrent",
                "concurrency",
                "8 arm",
                "worker pool",
                "limit concurrency",
                "bouncer",
            ),
            ("lock", "mutex", "acquire", "exclusive", "atomic", "race"),
        ),
        "bounded queue": (
            (
                "bounded queue",
                "bounded",
                "max_queue",
                "queue_depth",
                "queue capacity",
                "queue limit",
                "buffer size",
                "memory",
                "oom",
                "out-of-memory",
                "out of memory",
            ),
            ("queue", "idempoten", "idempotency_key", "ledger", "ticket", "ring buffer", "backpressure"),
        ),
        "finally": (
            (
                "finally",
                "release",
                "unlock",
                "cleanup",
                "permit leak",
                "leak",
                "deadlock",
                "exception",
                "bladejam",
            ),
            ("ttl", "expir", "lease", "timeout", "retry", "retries", "twice", "double", "safe", "guard"),
        ),
        "ttl": (
            (
                "ttl",
                "time to live",
                "time-to-live",
                "expir",
                "lease",
                "timeout",
                "stale lock",
                "deadlock",
                "fencing",
            ),
            ("release", "finally", "unlock"),
        ),
        # --- Chapter 2: Candle Safety FSM (FSM / State / Sequence / Breaker) ---
        "fsm": (
            (
                "fsm",
                "state machine",
                "finite state",
                "candlestate",
                "state transition",
                "unlit",
                "igniting",
                "sparking",
                "flickering",
                "extinguished",
            ),
            ("state", "transition", "guard", "sequence", "breaker"),
        ),
        "state": (
            (
                "state",
                "fsm",
                "state machine",
                "candlestate",
                "transition",
                "unlit",
                "igniting",
                "sparking",
                "lit",
                "extinguished",
                "cooldown",
                "lockout",
            ),
            ("sequence", "guard", "breaker", "invariant"),
        ),
        "state machine": (
            (
                "state machine",
                "fsm",
                "finite state",
                "candlestate",
                "state",
                "unlit",
                "igniting",
                "sparking",
                "lit",
                "extinguished",
                "flickering",
            ),
            ("transition", "sequence", "breaker"),
        ),
        "transition guard": (
            (
                "transition guard",
                "allowed_transitions",
                "invalid transition",
                "transition",
                "guard",
                "double-spark",
                "sequence",
                "sequence_number",
                "last_seq",
                "out-of-order",
                "monotonic",
                "stale packet",
            ),
            ("state", "lock", "version", "cas", "invariant"),
        ),
        "sequence": (
            (
                "sequence",
                "sequence_number",
                "last_seq",
                "out-of-order",
                "out of order",
                "monotonic",
                "packet order",
                "stale",
                "older packet",
                "replay",
                "udp",
            ),
            ("transition", "guard", "version", "timestamp", "state"),
        ),
        "breaker": (
            (
                "breaker",
                "circuit breaker",
                "trip",
                "half-open",
                "half_open",
                "open state",
                "lockout",
                "thermal",
                "overheat",
                "extinguish",
                "cutoff",
                "shutoff",
            ),
            ("cooldown", "overload", "surge", "spike", "safety"),
        ),
        "circuit breaker": (
            (
                "circuit breaker",
                "breaker",
                "trip",
                "half-open",
                "half_open",
                "lockout",
                "thermal",
                "overheat",
                "cutoff",
            ),
            ("cooldown", "overload", "surge", "safety"),
        ),
        "cooldown": (
            (
                "cooldown",
                "cool-down",
                "cool down",
                "vent",
                "vapor",
                "methane",
                "gas",
                "blowout",
                "double-spark",
                "thermal",
                "overheat",
                "lockout",
            ),
            ("breaker", "circuit breaker", "wait", "delay", "pause", "sleep"),
        ),
        "jitter": (
            (
                "jitter",
                "backoff",
                "exponential",
                "random",
                "thundering herd",
                "synchronized",
                "lockstep",
                "power grid",
                "current spike",
                "surge",
                "stagger",
                "relight",
            ),
            ("breaker", "circuit breaker", "overload", "retry", "delay"),
        ),
        # --- Chapter 3: Candy Escrow Saga (Optimistic / Version / Rollback / Saga) ---
        "optimistic": (
            (
                "optimistic",
                "occ",
                "optimistic concurrency",
                "optimistic locking",
                "cas",
                "compare-and-swap",
                "compare and swap",
                "lock-free",
                "conflict detection",
            ),
            ("version", "expected_version", "concurrent", "conflict", "retry"),
        ),
        "version": (
            (
                "version",
                "expected_version",
                "version check",
                "version number",
                "cas",
                "compare-and-swap",
                "increment",
                "stale write",
                "revision",
            ),
            ("optimistic", "occ", "idempoten", "tx_id", "conflict"),
        ),
        "rollback": (
            (
                "rollback",
                "roll back",
                "unwind",
                "revert",
                "undo",
                "reverse",
                "lifo",
                "restore",
                "restock",
                "release_candy",
                "recall",
                "abort",
                "rewind",
            ),
            ("compensat", "saga", "except", "failure", "recover"),
        ),
        "saga": (
            (
                "saga",
                "orchestrat",
                "distributed transaction",
                "multi-step",
                "eventual consistency",
                "2pc",
                "two-phase",
                "across service",
                "microservice",
            ),
            ("compensat", "rollback", "Undo", "reserve"),
        ),
        "compensating transaction": (
            (
                "compensat",
                "compensation",
                "compensating transaction",
                "compensation_stack",
                "inverse action",
                "undo",
                "reverse order",
                "lifo",
                "release_candy",
                "recall_broomstick",
                "restock",
            ),
            ("optimistic", "occ", "version", "cas", "rollback", "saga"),
        ),
        # --- Chapter 4: 500-Skeleton Sync (Ring Buffer / Backpressure / Drop / Memory / Clock) ---
        "ring buffer": (
            (
                "ring buffer",
                "ring_buffer",
                "circular buffer",
                "circular queue",
                "bounded buffer",
                "deque",
                "cauldron",
                "fixed capacity",
                "fixed-size",
            ),
            ("buffer", "queue", "bounded", "capacity", "popleft", "drop"),
        ),
        "drop": (
            (
                "drop",
                "drop-oldest",
                "drop oldest",
                "popleft",
                "evict",
                "discard",
                "skip",
                "shed",
                "oldest frame",
                "stale frame",
                "late frame",
                "overwrite",
            ),
            ("ring buffer", "backpressure", "overflow", "freshness", "barrier"),
        ),
        "memory": (
            (
                "memory",
                "oom",
                "out-of-memory",
                "out of memory",
                "ram",
                "heap",
                "bounded",
                "max_capacity",
                "capacity",
                "o(1)",
                "unbounded",
                "explode",
                "leak",
            ),
            ("ring buffer", "buffer", "backpressure", "drop", "timeout"),
        ),
        "clock drift": (
            (
                "clock drift",
                "drift",
                "offset",
                "clock_offset",
                "smoothed_offset",
                "ntp",
                "skew",
                "clock sync",
                "phase",
                "ema",
            ),
            ("ring buffer", "ring_buffer", "deque", "bounded", "cauldron", "buffer", "clock", "sync"),
        ),
        "monotonic": (
            (
                "monotonic",
                "time.monotonic",
                "wall-clock",
                "wall clock",
                "datetime.now",
                "forward-marching",
                "hardware tick",
            ),
            ("backpressure", "back-pressure", "head-of-line", "hol", "60hz", "60fps", "freshness", "real-time"),
        ),
        "barrier": (
            (
                "barrier",
                "framebarrier",
                "wait_for_beat",
                "quorum",
                "chorus",
                "ensemble",
                "lockstep",
                "all 500",
                "straggler",
            ),
            ("drop", "drop-oldest", "popleft", "evict", "discard", "skip", "oldest", "stale"),
        ),
        "timeout": (
            (
                "timeout",
                "wait_for",
                "16ms",
                "16.6ms",
                "frame_budget",
                "frame budget",
                "stall",
                "freeze",
                "dead battery",
                "outlier",
                "rtt",
            ),
            ("memory", "oom", "out-of-memory", "ram", "bounded", "capacity", "max_capacity"),
        ),
    }

    # Socratic follow-up templates tailored to specific missing concepts
    _CONCEPT_SOCRATIC_QUESTIONS: Dict[str, str] = {
        "idempotency": (
            "What happens if a spooky network hiccup causes the same carving webhook to arrive twice—"
            "how does an `idempotency_key` ledger stop Choppy-Bot from slicing an already-carved pumpkin?"
        ),
        "idempotency_key": (
            "If the client retries after a timeout, how does checking `req.idempotency_key` let us "
            "return the cached carving result instead of firing the laser twice?"
        ),
        "duplicate": (
            "When duplicate requests hit our dispatcher during a retry storm, how do we detect and "
            "short-circuit those duplicates before touching the hardware?"
        ),
        "lock": (
            "If two worker coroutines receive the same request on the exact same millisecond, how does "
            "acquiring a distributed lock or mutex prevent a race-condition collision?"
        ),
        "distributed lock": (
            "Why do we need an atomic distributed lock (`SET NX` with TTL) before executing the physical "
            "carving G-code?"
        ),
        "backpressure": (
            "When 10,000 pumpkins flood the chute at midnight and the queue hits capacity, how does "
            "fast-fail backpressure (HTTP 429 shedding) protect the system from collapsing?"
        ),
        "semaphore": (
            "Why must each coroutine acquire the 8-permit worker semaphore *before* hydrating the heavy "
            "50MB 3D pumpkin mesh into RAM?"
        ),
        "bounded queue": (
            "Why do we cap waiting requests in a bounded queue (or idempotent ledger) instead of letting "
            "in-memory tasks accumulate without limit?"
        ),
        "finally": (
            "If a tough pumpkin rind snaps a blade and raises `BladeJamException`, why is releasing the "
            "lock/semaphore inside a `finally` block (or enforcing a lock TTL) essential to avoid a permanent deadlock?"
        ),
        "ttl": (
            "What happens if a worker crashes while holding a lock—how does a lock TTL (Time-To-Live) "
            "or fencing token prevent the pumpkin station from staying locked forever?"
        ),
        "fsm": (
            "How does modeling the candle as an explicit Finite State Machine (FSM) prevent illegal jumps "
            "like leaping straight from `EXTINGUISHED` to `LIT` without `SPARKING`?"
        ),
        "state": (
            "Why must every candle state transition be validated against `ALLOWED_TRANSITIONS` instead of "
            "mutating `self.state` directly?"
        ),
        "state machine": (
            "How does the Candle Finite State Machine enforce strict state invariants so two overlapping "
            "`SPARKING` commands can never double-open the fuel valve?"
        ),
        "transition guard": (
            "How do our transition guards and monotonic `sequence_number` checks stop a delayed, out-of-order "
            "`EXTINGUISH` packet from blowing out a newly relit candle?"
        ),
        "sequence": (
            "If UDP telemetry packets arrive out of order across the graveyard Wi-Fi, how does tracking a "
            "monotonic `sequence_number` protect the FSM from stale zombie commands?"
        ),
        "breaker": (
            "When internal pumpkin temperature spikes dangerously high, how does the thermal circuit breaker "
            "trip into lockout to prevent a Jack-o'-Lantern meltdown?"
        ),
        "circuit breaker": (
            "How does the 3-state (`CLOSED` / `OPEN` / `HALF_OPEN`) thermal circuit breaker isolate "
            "overheating candles before they catch fire?"
        ),
        "cooldown": (
            "Why does a failed piezo spark force the candle into a mandatory `COOLDOWN` / circuit-breaker "
            "lockout state before another ignition attempt is allowed?"
        ),
        "jitter": (
            "If a single graveyard wind gust blows out all 500 candles at once, why do we add random "
            "exponential backoff jitter before relighting instead of retrying at fixed intervals?"
        ),
        "optimistic": (
            "How does Optimistic Concurrency Control (CAS version checking) let multiple goblins update "
            "candy stock without holding slow distributed database locks?"
        ),
        "version": (
            "When two concurrent orders try to claim the last peanut-free chocolate bar, how does checking "
            "and incrementing the `version` column prevent a lost update?"
        ),
        "rollback": (
            "If the lollipop chute jams on Step 3 after chocolate and gummies were already reserved, how "
            "does reverse-order rollback restore the vault inventory?"
        ),
        "saga": (
            "Why did we orchestrate multi-service candy checkout as an asynchronous Saga instead of locking "
            "all three databases with Two-Phase Commit (2PC)?"
        ),
        "compensating transaction": (
            "Since microservices commit local transactions immediately, how do LIFO compensating transactions "
            "(paired with optimistic version checks) undo partial reservations when a downstream step fails?"
        ),
        "ring buffer": (
            "How does a fixed-capacity ring buffer (`deque`) keep per-skeleton choreography queues fast and "
            "bounded at 60 frames per second?"
        ),
        "drop": (
            "When Skeleton #42 lags behind during a Wi-Fi hiccup, why is dropping the oldest stale frames "
            "(`popleft`) better than playing old dance moves late?"
        ),
        "memory": (
            "Without a bounded capacity limit and frame eviction, what happens to server RAM (OOM) when "
            "60Hz motion packets pile up for lagging skeletons?"
        ),
        "clock drift": (
            "How do we compensate for hardware clock drift across 500 wireless skeletons using smoothed "
            "offset estimation (or bounded ring-buffer sync)?"
        ),
        "monotonic": (
            "Why must real-time 60Hz frame scheduling rely on `time.monotonic()` (and non-blocking backpressure) "
            "instead of wall-clock `datetime.now()`?"
        ),
        "barrier": (
            "When coordinating 500 skeletons on the same beat, how do we use a frame barrier (or drop-oldest "
            "eviction) so one lagging skeleton doesn't ruin ensemble harmony?"
        ),
        "timeout": (
            "What happens to the 499 healthy dancers if a frame barrier waits without a strict 16ms timeout "
            "(or bounded memory cap) when Skeleton #13's battery dies?"
        ),
    }

    _CAUSAL_REASONING_MARKERS: Tuple[str, ...] = (
        "because",
        "so that",
        "prevents",
        "prevent",
        "otherwise",
        "without",
        "avoid",
        "ensure",
        "guarantees",
        "guarantee",
        "when",
        "if ",
        "instead of",
        "in order to",
        "protects",
        "therefore",
    )

    def evaluate(
        self,
        chapter_or_request: Union[DidacticChapter, FeynmanVoiceRequest],
        request_or_chapter: Optional[Union[FeynmanVoiceRequest, DidacticChapter, str, Dict[str, object]]] = None,
        *,
        chapter_mastery_percentage: Optional[int] = None,
        overall_mastery_percentage: Optional[int] = None,
        ready_to_merge_pr: Optional[bool] = None,
        all_chapters: Optional[Sequence[DidacticChapter]] = None,
    ) -> FeynmanVoiceFeedback:
        """Evaluate a developer's spoken Feynman explanation against a chapter's required concepts.

        Accepts `(chapter, request)` (standard) or `(request, chapter)` for caller flexibility.
        """
        chapter, request = self._normalize_inputs(chapter_or_request, request_or_chapter)

        transcript = (request.spoken_transcript or "").strip()
        required_concepts = list(chapter.assessment.required_concepts_for_feynman or [])

        matched_concepts, missing_concepts = self.match_concepts(
            spoken_transcript=transcript,
            required_concepts=required_concepts,
        )

        comprehension_score = self._compute_comprehension_score(
            spoken_transcript=transcript,
            audio_duration_seconds=request.audio_duration_seconds,
            matched_concepts=matched_concepts,
            required_concepts=required_concepts,
        )
        passed = comprehension_score >= self.PASSING_SCORE_THRESHOLD

        # Update chapter state in-place for stateful pipeline callers
        chapter.feynman_score = comprehension_score

        resolved_chapter_mastery = (
            chapter_mastery_percentage
            if chapter_mastery_percentage is not None
            else self._compute_chapter_mastery(chapter, comprehension_score, passed)
        )
        chapter.mastery_percentage = resolved_chapter_mastery

        if overall_mastery_percentage is not None:
            resolved_overall_mastery = overall_mastery_percentage
        elif all_chapters:
            resolved_overall_mastery = int(
                round(
                    sum(c.mastery_percentage for c in all_chapters)
                    / max(len(all_chapters), 1)
                )
            )
        else:
            resolved_overall_mastery = resolved_chapter_mastery

        if ready_to_merge_pr is not None:
            resolved_ready_to_merge = ready_to_merge_pr
        elif all_chapters:
            resolved_ready_to_merge = all(
                c.mastery_percentage >= self.PASSING_SCORE_THRESHOLD
                for c in all_chapters
            )
        else:
            resolved_ready_to_merge = (
                passed and resolved_overall_mastery >= self.PASSING_SCORE_THRESHOLD
            )

        rubber_duck_reply = self._build_rubber_duck_reply(
            chapter=chapter,
            comprehension_score=comprehension_score,
            passed=passed,
            matched_concepts=matched_concepts,
            missing_concepts=missing_concepts,
        )
        socratic_follow_up = self._build_socratic_follow_up(
            chapter=chapter,
            missing_concepts=missing_concepts,
            matched_concepts=matched_concepts,
        )

        return FeynmanVoiceFeedback(
            chapter_id=chapter.chapter_id,
            comprehension_score=comprehension_score,
            passed=passed,
            matched_concepts=matched_concepts,
            missing_concepts=missing_concepts,
            rubber_duck_reply=rubber_duck_reply,
            socratic_follow_up=socratic_follow_up,
            chapter_mastery_percentage=resolved_chapter_mastery,
            overall_mastery_percentage=resolved_overall_mastery,
            ready_to_merge_pr=resolved_ready_to_merge,
        )

    # Ergonomic method aliases so any caller convention works seamlessly
    evaluate_voice = evaluate
    evaluate_feynman = evaluate
    assess = evaluate

    # ------------------------------------------------------------------
    # Semantic & Synonym Concept Matching
    # ------------------------------------------------------------------

    def match_concepts(
        self,
        spoken_transcript: str,
        required_concepts: Sequence[str],
    ) -> Tuple[List[str], List[str]]:
        """Match required concepts against `spoken_transcript` using semantic synonyms."""
        normalized_transcript = self._normalize_text(spoken_transcript)
        if not normalized_transcript:
            return [], list(required_concepts)

        normalized_required_set: Set[str] = {
            self._normalize_text(c) for c in required_concepts
        }

        matched: List[str] = []
        missing: List[str] = []

        for concept in required_concepts:
            if self._concept_matches_transcript(
                concept=concept,
                normalized_transcript=normalized_transcript,
                normalized_required_set=normalized_required_set,
            ):
                matched.append(concept)
            else:
                missing.append(concept)

        return matched, missing

    def _concept_matches_transcript(
        self,
        concept: str,
        normalized_transcript: str,
        normalized_required_set: Set[str],
    ) -> bool:
        norm_concept = self._normalize_text(concept)
        if not norm_concept:
            return False

        # 1. Exact phrase match in normalized transcript
        if norm_concept in normalized_transcript:
            return True

        # 2. Content-token stem match (e.g., "compensating transaction" -> "compensat" + "transaction")
        tokens = [
            tok
            for tok in norm_concept.split()
            if len(tok) >= 3 and tok not in {"the", "and", "for", "with", "from", "into"}
        ]
        if tokens and all(
            self._stem_in_text(tok, normalized_transcript) for tok in tokens
        ):
            return True

        # 3. Curated primary & family fallback synonyms
        primary_syns, fallback_syns = self._get_synonyms_for_concept(norm_concept)

        for syn in primary_syns:
            if self._phrase_or_stem_in_text(syn, normalized_transcript):
                return True

        # Use family fallback synonyms unless another required concept in the same chapter
        # is explicitly named after that fallback synonym (prevents 1 keyword matching 2 sibling concepts
        # when both are listed separately in `required_concepts_for_feynman`).
        for syn in fallback_syns:
            norm_syn = self._normalize_text(syn)
            if norm_syn in normalized_required_set and norm_syn != norm_concept:
                continue
            if self._phrase_or_stem_in_text(syn, normalized_transcript):
                return True

        return False

    def _get_synonyms_for_concept(
        self, norm_concept: str
    ) -> Tuple[Tuple[str, ...], Tuple[str, ...]]:
        """Retrieve primary and fallback synonyms for a normalized concept name."""
        if norm_concept in self._CONCEPT_SYNONYMS:
            return self._CONCEPT_SYNONYMS[norm_concept]

        # Stem-based lookup if a custom concept string contains known domain terms
        combined_primary: List[str] = []
        combined_fallback: List[str] = []
        for key, (prim, fall) in self._CONCEPT_SYNONYMS.items():
            if key in norm_concept or norm_concept in key:
                combined_primary.extend(prim)
                combined_fallback.extend(fall)

        return tuple(combined_primary), tuple(combined_fallback)

    @staticmethod
    def _normalize_text(text: str) -> str:
        """Lowercase and normalize punctuation/underscores/hyphens into clean spaces."""
        lowered = text.lower()
        # Keep alphanumeric, spaces, and convert underscores/hyphens/slashes to spaces
        cleaned = re.sub(r"[_\-/]+", " ", lowered)
        cleaned = re.sub(r"[^a-z0-9\s().]", " ", cleaned)
        return re.sub(r"\s+", " ", cleaned).strip()

    @classmethod
    def _stem_in_text(cls, token: str, normalized_transcript: str) -> bool:
        """Check whether a token or its root stem appears in `normalized_transcript`."""
        if token in normalized_transcript:
            return True
        if len(token) >= 6:
            stem = token[: max(5, len(token) - 3)]
            if stem in normalized_transcript:
                return True
        return False

    @classmethod
    def _phrase_or_stem_in_text(cls, synonym: str, normalized_transcript: str) -> bool:
        norm_syn = cls._normalize_text(synonym)
        if not norm_syn:
            return False
        if norm_syn in normalized_transcript:
            return True
        # For single-word stems like "idempoten" or "compensat", substring match is already handled above.
        # For multi-word phrases, check if all words/stems appear close together or in the transcript.
        parts = norm_syn.split()
        if len(parts) > 1 and all(
            cls._stem_in_text(part, normalized_transcript) for part in parts
        ):
            return True
        return False

    # ------------------------------------------------------------------
    # Scoring & Mastery Computation
    # ------------------------------------------------------------------

    def _compute_comprehension_score(
        self,
        spoken_transcript: str,
        audio_duration_seconds: float,
        matched_concepts: Sequence[str],
        required_concepts: Sequence[str],
    ) -> int:
        if not spoken_transcript or not spoken_transcript.strip():
            return 0

        words = spoken_transcript.split()
        word_count = len(words)

        if not required_concepts:
            return min(100, 75 + min(25, word_count)) if word_count >= 5 else 20

        total_required = len(required_concepts)
        matched_count = len(matched_concepts)
        concept_ratio = matched_count / total_required

        if matched_count == 0:
            # Effort credit for speaking, but never near passing without matching concepts
            return min(18, max(5, word_count // 2))

        lowered = spoken_transcript.lower()
        causal_hits = sum(
            1 for marker in self._CAUSAL_REASONING_MARKERS if marker in lowered
        )
        depth_bonus = 0
        if word_count >= 10:
            depth_bonus += 4
        if word_count >= 22:
            depth_bonus += 4
        if causal_hits >= 1:
            depth_bonus += 4
        if causal_hits >= 2 or audio_duration_seconds >= 12.0:
            depth_bonus += 3

        if matched_count == total_required:
            # 100% concept coverage guarantees >= 85 (up to 100 with explanation depth)
            raw_score = 85 + depth_bonus
        elif concept_ratio >= 0.70:
            # e.g., 3 out of 4 concepts matched -> passing score (72..86)
            raw_score = 72 + int(round((concept_ratio - 0.70) * 30)) + min(10, depth_bonus)
        else:
            # Partial concept coverage (< 70% concepts) stays below 70 threshold
            raw_score = int(round(concept_ratio * 80)) + min(8, depth_bonus // 2)
            raw_score = min(self.PASSING_SCORE_THRESHOLD - 2, raw_score)

        return max(0, min(100, raw_score))

    def _compute_chapter_mastery(
        self,
        chapter: DidacticChapter,
        comprehension_score: int,
        passed: bool,
    ) -> int:
        """Compute updated chapter mastery percentage (0-100)."""
        has_progress_tracking = bool(chapter.scene_completed or chapter.answered_cards)
        if not has_progress_tracking:
            return max(chapter.mastery_percentage, comprehension_score)

        scene_points = 30 if chapter.scene_completed else 0
        total_cards = max(len(chapter.assessment.flip_cards), 1)
        correct_cards = sum(1 for knew in chapter.answered_cards.values() if knew)
        card_points = int(round(35 * (correct_cards / total_cards)))
        feynman_points = int(round(35 * (comprehension_score / 100.0)))

        weighted = scene_points + card_points + feynman_points
        if passed:
            weighted = max(weighted, comprehension_score)
        return max(0, min(100, max(chapter.mastery_percentage, weighted)))

    # ------------------------------------------------------------------
    # Persona Replies & Socratic Follow-up Generation
    # ------------------------------------------------------------------

    def _build_rubber_duck_reply(
        self,
        chapter: DidacticChapter,
        comprehension_score: int,
        passed: bool,
        matched_concepts: Sequence[str],
        missing_concepts: Sequence[str],
    ) -> str:
        matched_str = (
            ", ".join(f"'{c}'" for c in matched_concepts)
            if matched_concepts
            else "the spooky high-level vibe"
        )

        if passed and not missing_concepts:
            return (
                f"🦆✨ *Quack-tastic!* {self.DUCK_PERSONA_NAME} adjusts his tiny witch hat and salutes you! "
                f"You nailed every core invariant of **{chapter.title}** ({matched_str}) with a "
                f"{comprehension_score}% comprehension score. My rubber feathers are 100% convinced "
                f"you can safely debug and merge this subsystem at midnight!"
            )

        if passed:
            missing_str = ", ".join(f"'{c}'" for c in missing_concepts)
            return (
                f"🦆🎃 *Spooky good job, human!* {self.DUCK_PERSONA_NAME} happily bobbles on your desk! "
                f"You clearly explained {matched_str} for **{chapter.title}** (scoring {comprehension_score}% "
                f"and passing the Feynman gate!). Just to polish your mental model to perfection, "
                f"let's briefly ponder {missing_str}."
            )

        if matched_concepts:
            missing_str = ", ".join(f"'{c}'" for c in missing_concepts)
            return (
                f"🦆🕯️ *Encouraging quack!* {self.DUCK_PERSONA_NAME} tilts his glowing bill—you're on the "
                f"right haunted trail for **{chapter.title}** by mentioning {matched_str} "
                f"(score: {comprehension_score}%), but my junior duck brain still has a gap around "
                f"{missing_str}. Take one more breath and walk me through the missing piece!"
            )

        missing_str = ", ".join(f"'{c}'" for c in missing_concepts)
        return (
            f"🦆👻 *Gentle spooky quack!* {self.DUCK_PERSONA_NAME} flutters his rubber wings "
            f"encouragingly! We scored {comprehension_score}% on **{chapter.title}** because I didn't "
            f"hear how the code handles {missing_str} yet. Don't worry—peek at the 3D scene or "
            f"FlipCards, then explain to me how those mechanisms prevent Halloween chaos!"
        )

    def _build_socratic_follow_up(
        self,
        chapter: DidacticChapter,
        missing_concepts: Sequence[str],
        matched_concepts: Sequence[str],
    ) -> str:
        """Generate a sharp Socratic follow-up question targeting any `missing_concepts`."""
        if missing_concepts:
            primary_missing = missing_concepts[0]
            norm_missing = self._normalize_text(primary_missing)
            specific_q = self._CONCEPT_SOCRATIC_QUESTIONS.get(norm_missing)

            if len(missing_concepts) == 1 and specific_q:
                return f"Quack-question on '{primary_missing}': {specific_q}"

            missing_list_str = ", ".join(f"'{c}'" for c in missing_concepts)
            if specific_q:
                return (
                    f"To unlock full mastery of {missing_list_str}: {specific_q} "
                    f"(And how does that connect to {', '.join(missing_concepts[1:])}?)"
                )

            return (
                f"If we removed {missing_list_str} from `{chapter.file_path}` during peak Halloween "
                f"traffic, what exact failure mode or data corruption would strike our haunted factory?"
            )

        # Stretch Socratic question when all required concepts were mastered
        matched_preview = ", ".join(f"'{c}'" for c in matched_concepts[:2]) or "these guards"
        return (
            f"Bonus Architect Quack: Now that you've mastered {matched_preview} in `{chapter.file_path}`, "
            f"what subtle edge case could still occur if a network partition or GC pause lasts longer "
            f"than our configured safety timeout?"
        )

    # ------------------------------------------------------------------
    # Input Normalization Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _normalize_inputs(
        first: Union[DidacticChapter, FeynmanVoiceRequest],
        second: Optional[Union[FeynmanVoiceRequest, DidacticChapter, str, Dict[str, object]]],
    ) -> Tuple[DidacticChapter, FeynmanVoiceRequest]:
        if isinstance(first, DidacticChapter):
            chapter = first
            if isinstance(second, FeynmanVoiceRequest):
                request = second
            elif isinstance(second, str):
                request = FeynmanVoiceRequest(spoken_transcript=second)
            elif isinstance(second, dict):
                request = FeynmanVoiceRequest(**second)  # type: ignore[arg-type]
            else:
                raise TypeError(
                    "Expected second argument to be FeynmanVoiceRequest, str, or dict."
                )
            return chapter, request

        if isinstance(first, FeynmanVoiceRequest) and isinstance(second, DidacticChapter):
            return second, first

        raise TypeError(
            "FeynmanVoiceEvaluator.evaluate expects (DidacticChapter, FeynmanVoiceRequest)."
        )
