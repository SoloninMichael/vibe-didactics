"""Shared Pydantic schemas for the Vibe Didactics AI Pipeline & Backend."""

from __future__ import annotations

from enum import Enum
from typing import Any, Dict, List, Optional

try:
    from pydantic import BaseModel, Field
except ImportError:
    class _FieldInfo:
        def __init__(self, default: Any = None, default_factory: Any = None, **kwargs: Any) -> None:
            self.default = default
            self.default_factory = default_factory

    def Field(default: Any = None, *, default_factory: Any = None, **kwargs: Any) -> Any:  # type: ignore[misc]
        return _FieldInfo(default=default, default_factory=default_factory, **kwargs)

    class BaseModel:  # type: ignore[no-redef]
        def __init__(self, **kwargs: Any) -> None:
            for cls in reversed(self.__class__.__mro__):
                if cls is object:
                    continue
                for attr, val in cls.__dict__.items():
                    if attr.startswith("_") or callable(val) or isinstance(val, property):
                        continue
                    if isinstance(val, _FieldInfo):
                        if val.default_factory is not None:
                            setattr(self, attr, val.default_factory())
                        else:
                            setattr(self, attr, val.default)
                    else:
                        setattr(self, attr, val)
            for k, v in kwargs.items():
                setattr(self, k, v)

        def model_dump(self) -> Dict[str, Any]:
            def _conv(obj: Any) -> Any:
                if isinstance(obj, BaseModel):
                    return obj.model_dump()
                if isinstance(obj, Enum):
                    return obj.value
                if isinstance(obj, list):
                    return [_conv(x) for x in obj]
                if isinstance(obj, dict):
                    return {k: _conv(v) for k, v in obj.items()}
                return obj
            return {k: _conv(v) for k, v in self.__dict__.items() if not k.startswith("_")}

        def dict(self) -> Dict[str, Any]:
            return self.model_dump()


class PipelineStageStatus(str, Enum):
    INGESTED = "INGESTED"
    DECOMPOSED = "DECOMPOSED"
    SCENE_GENERATED = "SCENE_GENERATED"
    SCENE_WATCHED = "SCENE_WATCHED"
    QUIZ_IN_PROGRESS = "QUIZ_IN_PROGRESS"
    MASTERED = "MASTERED"


class DidacticTechnique(str, Enum):
    DUAL_CODING_3D = "dual_coding_3d_metaphor"
    COUNTERFACTUAL_BREAK_IT = "counterfactual_break_it"
    SOCRATIC_MAIEUTICS = "socratic_maieutics"
    ACTIVE_RECALL_FLIPCARD = "active_recall_flipcard"
    PARSONS_PUZZLE = "parsons_flow_reconstruction"
    FEYNMAN_RUBBER_DUCK = "feynman_rubber_duck_voice"
    SPIRAL_ELI5 = "spiral_progressive_depth"


class IngestRequest(BaseModel):
    repo_name: str = Field(
        default="spooky-pumpkin-factory-os",
        description="Name of the repository or PR being analyzed",
    )
    pr_title: str = Field(
        default="feat(halloween): AI-generated autonomous Pumpkin Carving, Candle FSM, Candy Saga & 500-Skeleton Sync",
        description="PR or branch title",
    )
    simulated_total_lines: int = Field(
        default=2_140_000,
        description="Total lines in the massive PR/monorepo before semantic Map-Reduce filtering",
    )
    target_branch: str = Field(default="feature/ai-halloween-overhaul")


class SubsystemHotspot(BaseModel):
    subsystem_id: str
    title: str
    file_path: str
    lines_of_code: int
    cyclomatic_complexity: int
    architectural_pattern: str
    risk_level: str
    why_hard_to_understand: str
    calls_to: List[str] = Field(default_factory=list)


class RepoIngestionSummary(BaseModel):
    repo_name: str
    pr_title: str
    target_branch: str
    total_raw_lines_scanned: int
    filtered_generated_or_vendor_lines: int
    core_architectural_lines: int
    compression_ratio: str
    mermaid_interaction_graph: str
    hotspots: List[SubsystemHotspot]


class SpiralExplanations(BaseModel):
    eli5_child: str = Field(description="Explain like I'm 5 using a Halloween story metaphor")
    junior_dev: str = Field(description="Practical code-level explanation for a junior developer")
    senior_architect: str = Field(description="Deep distributed systems & trade-offs analysis")


class CounterfactualMutation(BaseModel):
    mutation_id: str
    title: str
    target_file: str
    target_line_range: str
    code_line_removed: str
    what_breaks_in_code: str
    cartoon_chaos_animation: str
    severity: str = "CRITICAL"


class Scene3DActor(BaseModel):
    actor_id: str
    name: str
    role_metaphor: str
    code_symbol: str
    file_path: str
    line_range: str
    shape_type: str = Field(description="e.g. pumpkin_bot, bouncer_bat, candy_vault, skeleton_conductor, cauldron_queue")
    color_hex: str
    position: List[float] = Field(description="[x, y, z] coordinates in the 3D scene")


class Scene3DConnection(BaseModel):
    from_actor_id: str
    to_actor_id: str
    label: str
    packet_type: str
    color_hex: str


class Scene3DAnimationStep(BaseModel):
    step_index: int
    act_title: str
    Active_actor_ids: List[str] = Field(default_factory=list)
    packet_flow: Optional[str] = None
    voiceover_narration: str
    code_highlight_file: str
    code_highlight_lines: str
    code_snippet: str
    duration_seconds: float = 5.0


class Scene3DPayload(BaseModel):
    chapter_id: str
    scene_title: str
    halloween_theme_setting: str
    video_storyboard_url: str
    interactive_player_url: str
    actors: List[Scene3DActor]
    connections: List[Scene3DConnection]
    steps: List[Scene3DAnimationStep]
    break_it_mutation: CounterfactualMutation


class FlipCard(BaseModel):
    card_id: str
    chapter_id: str
    front_question: str
    socratic_hint: str
    back_answer: str
    code_reference_file: str
    code_reference_lines: str
    code_snippet: str
    difficulty: str = Field(description="EASY | MEDIUM | HARD")
    didactic_technique: DidacticTechnique = DidacticTechnique.ACTIVE_RECALL_FLIPCARD


class ParsonsBlock(BaseModel):
    block_id: str
    correct_order_index: int
    label: str
    code_line: str


class ChapterDidacticAssessment(BaseModel):
    chapter_id: str
    unlocked: bool = Field(description="True only after the developer watches/completes the 3D scene")
    locked_reason: Optional[str] = None
    socratic_opening_question: str
    flip_cards: List[FlipCard]
    parsons_blocks_shuffled: List[ParsonsBlock]
    feynman_prompt: str
    required_concepts_for_feynman: List[str]


class DidacticChapter(BaseModel):
    chapter_id: str
    order_index: int
    title: str
    subtitle: str
    file_path: str
    architectural_pattern: str
    spiral_explanations: SpiralExplanations
    scene_3d: Scene3DPayload
    assessment: ChapterDidacticAssessment
    scene_completed: bool = False
    answered_cards: Dict[str, bool] = Field(default_factory=dict)
    feynman_score: Optional[int] = None
    mastery_percentage: int = 0


class PipelineRunState(BaseModel):
    run_id: str
    stage_status: PipelineStageStatus
    ingestion_summary: RepoIngestionSummary
    chapters: List[DidacticChapter]
    overall_mastery_percentage: int = 0
    ready_to_merge_pr: bool = False


class FlipCardAnswerRequest(BaseModel):
    card_id: str
    knew_answer: bool = Field(description="True if swiped right (got it), False if swiped left (explain simpler)")


class FlipCardAnswerResponse(BaseModel):
    card_id: str
    knew_answer: bool
    follow_up_message: str
    simplified_metaphor: Optional[str] = None
    chapter_mastery_percentage: int
    overall_mastery_percentage: int


class FeynmanVoiceRequest(BaseModel):
    spoken_transcript: str = Field(
        description="Transcribed voice explanation from the developer explaining the chapter to the Rubber Duck"
    )
    audio_duration_seconds: float = Field(default=15.0)


class FeynmanVoiceFeedback(BaseModel):
    chapter_id: str
    comprehension_score: int = Field(ge=0, le=100)
    passed: bool
    matched_concepts: List[str]
    missing_concepts: List[str]
    rubber_duck_reply: str
    socratic_follow_up: Optional[str] = None
    chapter_mastery_percentage: int
    overall_mastery_percentage: int
    ready_to_merge_pr: bool
