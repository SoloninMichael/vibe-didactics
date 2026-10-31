"""End-to-end verification tests for data/mock_halloween_app and the Vibe Didactics backend pipeline."""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
BACKEND_DIR = ROOT_DIR / "backend"
DATA_DIR = ROOT_DIR / "data"

for p in (str(BACKEND_DIR), str(DATA_DIR)):
    if p not in sys.path:
        sys.path.insert(0, p)

from app.pipeline.orchestrator import DidacticPipelineOrchestrator
from app.schemas import FeynmanVoiceRequest, FlipCardAnswerRequest
from mock_halloween_app.orchestrator import HalloweenNightOrchestrator


def test_mock_halloween_app_simulation() -> None:
    orchestrator = HalloweenNightOrchestrator()
    summary = asyncio.run(orchestrator.simulate_halloween_night())
    assert len(summary.carving_results) >= 1
    assert len(summary.candle_states) >= 1
    assert len(summary.candy_dispatches) >= 1
    assert len(summary.synced_frames) >= 1


def test_didactic_pipeline_end_to_end_flow() -> None:
    pipeline = DidacticPipelineOrchestrator()
    run = pipeline.get_run("default")

    # Stage 1: Verify 2.14M-line PR filtering & 4 Halloween subsystems
    assert run.ingestion_summary.total_raw_lines_scanned == 2_140_000
    assert len(run.chapters) == 4
    first_ch = run.chapters[0]
    assert first_ch.chapter_id == "sub_1_carving"
    assert first_ch.file_path.startswith("data/mock_halloween_app/")

    # Stage 2 & 3: Verify 3D Cartoon Scene & Counterfactual Break-It mutation exist
    assert len(first_ch.scene_3d.actors) >= 4
    assert len(first_ch.scene_3d.steps) == 3
    assert first_ch.scene_3d.break_it_mutation.code_line_removed

    # Stage 4: Verify Flip Cards are initially gated until 3D Scene is watched
    assert first_ch.assessment.unlocked is False
    assert len(first_ch.assessment.flip_cards) == 4

    # Watch 3D Scene -> Unlock Flip Cards
    unlocked_ch = pipeline.mark_scene_completed("default", "sub_1_carving")
    assert unlocked_ch.scene_completed is True
    assert unlocked_ch.assessment.unlocked is True

    # Swipe Flip Card Left (need simpler metaphor) -> get child-friendly metaphor
    card_id = unlocked_ch.assessment.flip_cards[0].card_id
    left_resp = pipeline.answer_flip_card(
        "default",
        "sub_1_carving",
        FlipCardAnswerRequest(card_id=card_id, knew_answer=False),
    )
    assert left_resp.simplified_metaphor is not None

    # Swipe Flip Cards Right -> increase mastery
    for card in unlocked_ch.assessment.flip_cards:
        pipeline.answer_flip_card(
            "default",
            "sub_1_carving",
            FlipCardAnswerRequest(card_id=card.card_id, knew_answer=True),
        )

    # Stage 5: Feynman Rubber-Duck Voice Check
    voice_resp = pipeline.evaluate_feynman_voice(
        "default",
        "sub_1_carving",
        FeynmanVoiceRequest(
            spoken_transcript=(
                "We use an idempotency key lock in Redis with a semaphore and bounded queue "
                "for backpressure, and release the lock in a finally block so retries never "
                "double-carve the same pumpkin."
            )
        ),
    )
    assert voice_resp.comprehension_score >= 70
    assert voice_resp.passed is True
    assert voice_resp.chapter_mastery_percentage >= 80
    assert voice_resp.ready_to_merge_pr is True


if __name__ == "__main__":
    test_mock_halloween_app_simulation()
    test_didactic_pipeline_end_to_end_flow()
    print("ALL PIPELINE AND HALLOWEEN APP TESTS PASSED!")
