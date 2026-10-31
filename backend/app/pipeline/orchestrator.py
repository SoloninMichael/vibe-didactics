"""Pipeline Orchestrator connecting Stages 1 -> 2 -> 3 -> 4 -> 5 of Vibe Didactics."""

from __future__ import annotations

import uuid
from typing import Dict, List, Optional

from app.pipeline.cartoon_engine import CartoonSceneEngine
from app.pipeline.decomposer import DidacticDecomposer
from app.pipeline.feynman_evaluator import FeynmanVoiceEvaluator
from app.pipeline.flipcard_engine import FlipCardAssessmentEngine
from app.pipeline.ingestor import RepoIngestor
from app.schemas import (
    DidacticChapter,
    FeynmanVoiceFeedback,
    FeynmanVoiceRequest,
    FlipCardAnswerRequest,
    FlipCardAnswerResponse,
    IngestRequest,
    PipelineRunState,
    PipelineStageStatus,
)


class DidacticPipelineOrchestrator:
    """Coordinates repo ingestion, didactic decomposition, 3D scene generation,
    post-scene gated Flip Cards, and Feynman voice evaluation.
    """

    def __init__(self) -> None:
        self.ingestor = RepoIngestor()
        self.decomposer = DidacticDecomposer()
        self.cartoon_engine = CartoonSceneEngine()
        self.flipcard_engine = FlipCardAssessmentEngine()
        self.feynman_evaluator = FeynmanVoiceEvaluator()
        self._runs: Dict[str, PipelineRunState] = {}
        # Initialize a default pre-computed run for instant demo & UI access
        self._runs["default"] = self.create_run(IngestRequest(), run_id="default")

    def create_run(
        self,
        request: Optional[IngestRequest] = None,
        run_id: Optional[str] = None,
    ) -> PipelineRunState:
        req = request or IngestRequest()
        resolved_run_id = run_id or f"run-{uuid.uuid4().hex[:8]}"

        # Stage 1: Ingest massive PR / repo from data/mock_halloween_app
        ingestion_summary = self.ingestor.ingest(req)

        # Stages 2, 3, 4: Build DidacticChapters
        chapters: List[DidacticChapter] = []
        for idx, hotspot in enumerate(ingestion_summary.hotspots, start=1):
            chapter_id = hotspot.subsystem_id
            decomposed = self.decomposer.decompose_subsystem(hotspot)
            scene_3d = self.cartoon_engine.generate_scene(chapter_id)
            assessment = self.flipcard_engine.generate_assessment(chapter_id)

            chapters.append(
                DidacticChapter(
                    chapter_id=chapter_id,
                    order_index=idx,
                    title=hotspot.title,
                    subtitle=f"{hotspot.architectural_pattern} ({hotspot.lines_of_code} LOC)",
                    file_path=hotspot.file_path,
                    architectural_pattern=hotspot.architectural_pattern,
                    spiral_explanations=decomposed.spiral_explanations,
                    scene_3d=scene_3d,
                    assessment=assessment,
                    scene_completed=False,
                    answered_cards={},
                    feynman_score=None,
                    mastery_percentage=0,
                )
            )

        run_state = PipelineRunState(
            run_id=resolved_run_id,
            stage_status=PipelineStageStatus.SCENE_GENERATED,
            ingestion_summary=ingestion_summary,
            chapters=chapters,
            overall_mastery_percentage=0,
            ready_to_merge_pr=False,
        )
        self._runs[resolved_run_id] = run_state
        return run_state

    def get_run(self, run_id: str = "default") -> PipelineRunState:
        if run_id in ("default", "latest") and "default" in self._runs:
            return self._runs["default"]
        if run_id not in self._runs:
            raise KeyError(f"Pipeline run '{run_id}' not found")
        return self._runs[run_id]

    def get_chapter(self, run_id: str, chapter_id: str) -> DidacticChapter:
        run = self.get_run(run_id)
        for ch in run.chapters:
            if ch.chapter_id == chapter_id:
                return ch
        raise KeyError(f"Chapter '{chapter_id}' not found in run '{run_id}'")

    def _recalculate_mastery(self, run: PipelineRunState, chapter: DidacticChapter) -> None:
        total_cards = max(1, len(chapter.assessment.flip_cards))
        knew_count = sum(1 for v in chapter.answered_cards.values() if v)
        card_score = int((knew_count / total_cards) * 50)
        scene_score = 20 if chapter.scene_completed else 0
        feynman_component = int((chapter.feynman_score or 0) * 0.30)
        chapter.mastery_percentage = min(100, scene_score + card_score + feynman_component)

        if run.chapters:
            run.overall_mastery_percentage = int(
                sum(c.mastery_percentage for c in run.chapters) / len(run.chapters)
            )
        run.ready_to_merge_pr = run.overall_mastery_percentage >= 75 or any(
            c.mastery_percentage >= 80 for c in run.chapters
        )
        if run.ready_to_merge_pr:
            run.stage_status = PipelineStageStatus.MASTERED

    def mark_scene_completed(self, run_id: str, chapter_id: str) -> DidacticChapter:
        run = self.get_run(run_id)
        chapter = self.get_chapter(run_id, chapter_id)
        chapter.scene_completed = True
        chapter.assessment.unlocked = True
        chapter.assessment.locked_reason = None
        if run.stage_status == PipelineStageStatus.SCENE_GENERATED:
            run.stage_status = PipelineStageStatus.SCENE_WATCHED
        self._recalculate_mastery(run, chapter)
        return chapter

    def answer_flip_card(
        self,
        run_id: str,
        chapter_id: str,
        request: FlipCardAnswerRequest,
    ) -> FlipCardAnswerResponse:
        run = self.get_run(run_id)
        chapter = self.get_chapter(run_id, chapter_id)
        # Auto-unlock if user answers directly
        chapter.scene_completed = True
        chapter.assessment.unlocked = True
        chapter.assessment.locked_reason = None
        chapter.answered_cards[request.card_id] = request.knew_answer
        run.stage_status = PipelineStageStatus.QUIZ_IN_PROGRESS
        self._recalculate_mastery(run, chapter)

        return self.flipcard_engine.evaluate_card_answer(
            chapter_id,
            request,
            chapter_mastery_percentage=chapter.mastery_percentage,
            overall_mastery_percentage=run.overall_mastery_percentage,
        )

    def evaluate_feynman_voice(
        self,
        run_id: str,
        chapter_id: str,
        request: FeynmanVoiceRequest,
    ) -> FeynmanVoiceFeedback:
        run = self.get_run(run_id)
        chapter = self.get_chapter(run_id, chapter_id)
        chapter.scene_completed = True
        chapter.assessment.unlocked = True
        feedback = self.feynman_evaluator.evaluate(
            chapter,
            request,
            all_chapters=run.chapters,
        )
        chapter.feynman_score = feedback.comprehension_score
        self._recalculate_mastery(run, chapter)
        feedback.chapter_mastery_percentage = chapter.mastery_percentage
        feedback.overall_mastery_percentage = run.overall_mastery_percentage
        feedback.ready_to_merge_pr = run.ready_to_merge_pr
        return feedback
