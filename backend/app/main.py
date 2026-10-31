"""FastAPI Backend Server for the Vibe Didactics AI Pipeline."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse

from app.pipeline.orchestrator import DidacticPipelineOrchestrator
from app.schemas import (
    ChapterDidacticAssessment,
    DidacticChapter,
    FeynmanVoiceFeedback,
    FeynmanVoiceRequest,
    FlipCardAnswerRequest,
    FlipCardAnswerResponse,
    IngestRequest,
    PipelineRunState,
    Scene3DPayload,
)

app = FastAPI(
    title="Vibe Didactics AI Pipeline API",
    description=(
        "Decomposes massive AI-generated PRs/repos into 3D Halloween Cartoon Scenes, "
        "Counterfactual 'Break-It' Mutations, Gated Flip Cards, and Feynman Rubber-Duck Voice Checks."
    ),
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

orchestrator = DidacticPipelineOrchestrator()
STATIC_DIR = Path(__file__).resolve().parents[1] / "static"


@app.get("/health")
def health_check() -> dict:
    return {
        "status": "ok",
        "service": "vibe-didactics-backend",
        "default_run_id": "default",
        "input_repo_path": "data/mock_halloween_app",
    }


@app.post("/api/v1/pipeline/ingest", response_model=PipelineRunState)
def ingest_repo(request: Optional[IngestRequest] = None) -> PipelineRunState:
    """Stage 1-3: Ingest a repository/PR (default: data/mock_halloween_app) and build didactic chapters."""
    return orchestrator.create_run(request=request)


@app.get("/api/v1/pipeline/runs/{run_id}", response_model=PipelineRunState)
def get_pipeline_run(run_id: str = "default") -> PipelineRunState:
    try:
        return orchestrator.get_run(run_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@app.get("/api/v1/pipeline/runs/{run_id}/chapters", response_model=List[DidacticChapter])
def list_chapters(run_id: str = "default") -> List[DidacticChapter]:
    try:
        return orchestrator.get_run(run_id).chapters
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@app.get(
    "/api/v1/pipeline/runs/{run_id}/chapters/{chapter_id}/scene",
    response_model=Scene3DPayload,
)
def get_chapter_scene(run_id: str, chapter_id: str) -> Scene3DPayload:
    try:
        return orchestrator.get_chapter(run_id, chapter_id).scene_3d
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@app.get("/api/v1/chapters/{chapter_id}/scene", response_model=Scene3DPayload)
def get_default_chapter_scene(chapter_id: str) -> Scene3DPayload:
    """Convenience route used by the embedded 3D WebGL scene player."""
    try:
        return orchestrator.get_chapter("default", chapter_id).scene_3d
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@app.post(
    "/api/v1/pipeline/runs/{run_id}/chapters/{chapter_id}/scene/complete",
    response_model=DidacticChapter,
)
def complete_chapter_scene(run_id: str, chapter_id: str) -> DidacticChapter:
    """Marks the 3D Cartoon Scene as watched and unlocks the Flip Cards assessment gate."""
    try:
        return orchestrator.mark_scene_completed(run_id, chapter_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@app.get(
    "/api/v1/pipeline/runs/{run_id}/chapters/{chapter_id}/flipcards",
    response_model=ChapterDidacticAssessment,
)
def get_chapter_flipcards(
    run_id: str,
    chapter_id: str,
    unlock: bool = Query(default=False, description="Force unlock if testing directly"),
) -> ChapterDidacticAssessment:
    """Returns post-scene Flip Cards & Parsons puzzle (gated until 3D scene is completed)."""
    try:
        if unlock:
            chapter = orchestrator.mark_scene_completed(run_id, chapter_id)
        else:
            chapter = orchestrator.get_chapter(run_id, chapter_id)
        return chapter.assessment
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@app.post(
    "/api/v1/pipeline/runs/{run_id}/chapters/{chapter_id}/flipcards/answer",
    response_model=FlipCardAnswerResponse,
)
def answer_flipcard(
    run_id: str,
    chapter_id: str,
    request: FlipCardAnswerRequest,
) -> FlipCardAnswerResponse:
    try:
        return orchestrator.answer_flip_card(run_id, chapter_id, request)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@app.post(
    "/api/v1/pipeline/runs/{run_id}/chapters/{chapter_id}/feynman-voice",
    response_model=FeynmanVoiceFeedback,
)
def evaluate_feynman_voice(
    run_id: str,
    chapter_id: str,
    request: FeynmanVoiceRequest,
) -> FeynmanVoiceFeedback:
    try:
        return orchestrator.evaluate_feynman_voice(run_id, chapter_id, request)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@app.get("/scene-player/{chapter_id}", response_class=HTMLResponse)
def serve_scene_player(chapter_id: str = "sub_1_carving") -> FileResponse:
    player_file = STATIC_DIR / "scene_player.html"
    if not player_file.is_file():
        raise HTTPException(status_code=404, detail="scene_player.html not found")
    return FileResponse(player_file, media_type="text/html")


VIDEO_LESSONS_JSON = (
    Path(__file__).resolve().parents[2]
    / "data"
    / "mock_halloween_app"
    / "video_lessons_and_questions.json"
)


@app.get("/api/v1/video-lessons")
def get_google_halloween_video_lessons() -> Dict[str, Any]:
    """Returns the 18-service Google Halloween diagram, 10s video storyboards (Video 1, 2A, 2B), and mock questions."""
    if not VIDEO_LESSONS_JSON.is_file():
        raise HTTPException(status_code=404, detail="video_lessons_and_questions.json not found")
    return json.loads(VIDEO_LESSONS_JSON.read_text(encoding="utf-8"))


@app.get("/api/v1/video-lessons/{video_id}")
def get_single_google_halloween_video_lesson(video_id: str) -> Dict[str, Any]:
    """Returns a single 10s video lesson and its mock questions by video_id."""
    if not VIDEO_LESSONS_JSON.is_file():
        raise HTTPException(status_code=404, detail="video_lessons_and_questions.json not found")
    payload = json.loads(VIDEO_LESSONS_JSON.read_text(encoding="utf-8"))
    for lesson in payload.get("video_lessons", []):
        if lesson.get("video_id") == video_id:
            return lesson
    raise HTTPException(status_code=404, detail=f"Video lesson '{video_id}' not found")
