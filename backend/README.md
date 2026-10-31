# Vibe Didactics — AI Didactic Pipeline & Backend

**Pedagogical Code Decomposition, 3D Cartoon Metaphor Engine & Active Comprehension API**

Modern AI coding assistants allow developers to generate massive, distributed features at unprecedented speed ("vibe coding"), but shipping uncomprehended code creates severe operational risk. The **Vibe Didactics Backend** transforms sprawling AI-generated pull requests into a structured, multi-stage interactive learning experience—combining **Dual-Coding 3D Halloween Cartoon Scenes**, **Counterfactual "Break-It" Simulations**, **Gated Socratic Flip Cards**, **Parsons Flow Reconstruction Puzzles**, and a **Feynman Rubber-Duck Voice Check**.

---

## End-to-End Didactic Flow

```text
[ 2M-Line PR / Repo ]
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Stage 1: AST & Map-Reduce Hotspots                                      │
│ Filters generated/vendor noise (~2.14M lines → core architectural LOC)  │
│ Ranks high-risk concurrency, FSM, and distributed transaction hotspots  │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Stage 2: Multimodal Didactic Decomposition (ELI5 + Counterfactuals)     │
│ Builds Spiral Explanations (ELI5 Child → Junior Dev → Senior Architect) │
│ Synthesizes Counterfactual "Break-It" mutations showing what explodes   │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Stage 3: 3D Halloween Cartoon Scene Engine                              │
│ Maps AST symbols & message flows to 3D actors, packets, and acts        │
│ Interactive WebGL/Three.js player synced with exact source line ranges  │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Stage 4: Gated Post-Scene Flip Cards & Parsons Puzzle                   │
│ Remains LOCKED until the developer finishes watching the 3D scene       │
│ Active Recall Flip Cards (swipe right/left) + Parsons code block order  │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Stage 5: Feynman Rubber-Duck Voice Check                                │
│ Developer explains the subsystem out loud to the Halloween Rubber Duck  │
│ Evaluates conceptual coverage & unlocks PR merge readiness at mastery   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Stage Breakdown

1. **Stage 1 — AST & Map-Reduce Hotspots (`INGESTED`)**: Parses the target repository and PR diff, stripping out lockfiles, vendor bundles, and boilerplate to isolate the core architectural hotspots by cyclomatic complexity and failure blast radius.
2. **Stage 2 — Multimodal Didactic Decomposition (`DECOMPOSED`)**: Generates progressive **Spiral Curriculum** explanations (`eli5_child`, `junior_dev`, `senior_architect`) alongside a **Counterfactual Mutation** (`break_it_mutation`) that demonstrates what breaks in production if a single critical guard line is removed.
3. **Stage 3 — 3D Halloween Cartoon Scene Engine (`SCENE_GENERATED` → `SCENE_WATCHED`)**: Translates abstract classes, queues, locks, and state transitions into an interactive 3D Halloween cartoon storyboard (`pumpkin_bot`, `bouncer_bat`, `candy_vault`, `skeleton_conductor`, `cauldron_queue`) with synchronized code highlighting and counterfactual chaos animations.
4. **Stage 4 — Gated Post-Scene Flip Cards & Parsons Puzzle (`QUIZ_IN_PROGRESS`)**: Enforces **comprehension gating**—assessment cards remain locked (`unlocked: false`) until the 3D scene for that chapter is completed. Once unlocked, developers practice **Active Recall** via Socratic Flip Cards (with automatic simplified metaphors when swiping "Explain Simpler") and reconstruct control flow with **Parsons Puzzles**.
5. **Stage 5 — Feynman Rubber-Duck Voice Check (`MASTERED`)**: Evaluates the developer's spoken explanation transcript against required architectural concepts, returning Socratic follow-ups from the Rubber Duck and unlocking `ready_to_merge_pr: true` once overall mastery reaches the target threshold.

---

## The Mock Target App (`mock_halloween_app/`)

To showcase Vibe Didactics on a realistic, high-stakes AI-generated codebase, `backend/mock_halloween_app/` contains **SpookyPrep-OS**—an autonomous **Halloween Pumpkin & Party Preparation Platform** featuring 4 complex distributed subsystems:

| Chapter / Subsystem ID | File Path | Architectural Pattern | What It Does & Why It's Tricky |
| :--- | :--- | :--- | :--- |
| **1. `pumpkin_carving`** | `mock_halloween_app/carving_dispatcher.py` | **Token-Bucket Backpressure + Idempotency Key Deduplication + Circuit Breaker** | Schedules high-power CNC laser rigs to carve fractal SVG faces (`PumpkinCarvingRequest`) into pumpkins without double-carving on network retries or melting laser diodes under spike load. |
| **2. `candle_fsm`** | `mock_halloween_app/candle_controller.py` | **Deterministic Finite State Machine (FSM) + Hysteresis & Thermal Lockout** | Processes real-time IoT telemetry (`CandleTelemetryPacket`: internal temp, wind gusts, oxygen ratio) across 6 states (`UNLIT` → `IGNITING` → `FLICKERING_NORMAL` → `WIND_GUST_ALERT` → `THERMAL_OVERHEAT` → `EXTINGUISHED_LOCKOUT`) while rejecting out-of-order UDP packets. |
| **3. `candy_inventory`** | `mock_halloween_app/candy_distributor.py` | **Saga Pattern (Reserve → Allergy Check → Commit/Compensate) + Optimistic Concurrency Control (OCC)** | Allocates limited candy batches (`CandySkuBatch`) to concurrent trick-or-treaters (`TrickOrTreaterOrder`), enforcing strict allergen safety barriers (`PEANUT`, `TREE_NUT`, `GLUTEN`, `DAIRY`) and rolling back partial reservations on version conflicts. |
| **4. `party_orchestrator`** | `mock_halloween_app/party_orchestrator.py` | **Pub/Sub Frame Clock Barrier + Deadlock-Free Lock Ordering + Graceful Degradation** | Synchronizes 500 animatronic yard skeletons and fog machines (`AnimatronicFrame`) to a 128 BPM Halloween soundtrack using canonical resource lock acquisition so two choreographers never deadlock the yard. |

---

## How to Run the Backend Server & Interactive 3D Scene Player

### 1. Install Dependencies

From the `vibe-didactics/backend` directory, create a virtual environment and install `requirements.txt`:

```bash
cd vibe-didactics/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Start the FastAPI Server

```bash
uvicorn app.main:app --reload --port 8000
```

### 3. Open the Interactive 3D Scene Player & API Docs

Once `uvicorn` is running on `http://localhost:8000`:

- **Interactive 3D Halloween Cartoon Player**: [http://localhost:8000/static/player.html](http://localhost:8000/static/player.html) (or `http://localhost:8000/player`)
  - Switch between all 4 Halloween chapters, step through animated acts with synchronized code snippets, and trigger the **"Break-It" Counterfactual Chaos Mode** in real time.
- **OpenAPI / Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **Run Automated Test Suite**:
  ```bash
  pytest -v
  ```

---

## Full API Reference & `curl` Walkthrough

### Endpoint Summary

| Method | Path | Description |
| :--- | :--- | :--- |
| `GET` | `/api/v1/health` | Health check and active pipeline status. |
| `POST` | `/api/v1/pipeline/ingest` | Trigger a fresh 5-stage didactic analysis run on a repo/PR. |
| `GET` | `/api/v1/pipeline/runs/latest` | Fetch the default pre-populated `PipelineRunState` (used on UI launch). |
| `GET` | `/api/v1/pipeline/runs/{run_id}` | Fetch a specific pipeline run by `run_id`. |
| `GET` | `/api/v1/pipeline/runs/{run_id}/chapters/{chapter_id}/scene` | Fetch the 3D Halloween cartoon scene payload & counterfactual mutation for a chapter. |
| `POST` | `/api/v1/pipeline/runs/{run_id}/chapters/{chapter_id}/complete-scene` | Mark the 3D scene as watched and **unlock** the post-scene Flip Cards & Parsons puzzle. |
| `POST` | `/api/v1/pipeline/runs/{run_id}/chapters/{chapter_id}/flip-cards/answer` | Submit a Flip Card swipe (`knew_answer: true/false`) and receive adaptive feedback + updated mastery. |
| `POST` | `/api/v1/pipeline/runs/{run_id}/chapters/{chapter_id}/feynman-voice` | Submit a spoken Feynman explanation to the Rubber Duck for concept grading. |

---

### Step-by-Step `curl` Walkthrough

Follow this sequence to simulate how the iOS / Web UI progresses a developer from **0% comprehension** to **PR Merge Ready**.

#### 1. Fetch the Latest Didactic Run (or Trigger Ingestion)

Fetch the default run (`run-halloween-2026`) containing the 2.14M-line Map-Reduce summary and all 4 chapters:

```bash
curl -s http://localhost:8000/api/v1/pipeline/runs/latest | python3 -m json.tool | head -n 40
```

Or trigger a custom ingestion run:

```bash
curl -s -X POST http://localhost:8000/api/v1/pipeline/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "repo_name": "spooky-pumpkin-factory-os",
    "pr_title": "feat(halloween): AI-generated autonomous Pumpkin Carving, Candle FSM, Candy Saga & 500-Skeleton Sync",
    "simulated_total_lines": 2140000,
    "target_branch": "feature/ai-halloween-overhaul"
  }' | python3 -m json.tool | head -n 35
```

> **Note**: In the initial response, each chapter's `assessment.unlocked` is `false` with `locked_reason`: `"Watch the 3D Halloween Cartoon Scene first so your visual mental model is anchored before testing active recall."`

#### 2. Fetch the 3D Cartoon Scene & Counterfactual "Break-It" Payload

Retrieve the 3D actors, connections, step-by-step animation timeline, and counterfactual mutation for Chapter 1 (`pumpkin_carving`):

```bash
curl -s http://localhost:8000/api/v1/pipeline/runs/run-halloween-2026/chapters/pumpkin_carving/scene \
  | python3 -m json.tool
```

#### 3. Complete the 3D Scene to Unlock the Flip Cards & Parsons Puzzle

Once the developer finishes watching the 3D animation in the player, notify the backend to unlock the chapter's assessment gate:

```bash
curl -s -X POST http://localhost:8000/api/v1/pipeline/runs/run-halloween-2026/chapters/pumpkin_carving/complete-scene \
  | python3 -m json.tool
```

This transitions the run stage to `SCENE_WATCHED`, sets `scene_completed: true` and `assessment.unlocked: true`, and awards initial visual mental-model mastery points.

#### 4. Answer the Post-Scene Flip Cards (Swipe Right / Swipe Left)

If the developer swipes **Left** (`"knew_answer": false` — *"Explain Simpler"*), the backend responds with an ELI5 simplified Halloween metaphor so they can re-learn the concept immediately:

```bash
curl -s -X POST http://localhost:8000/api/v1/pipeline/runs/run-halloween-2026/chapters/pumpkin_carving/flip-cards/answer \
  -H "Content-Type: application/json" \
  -d '{
    "card_id": "card_carving_1",
    "knew_answer": false
  }' | python3 -m json.tool
```

When the developer swipes **Right** (`"knew_answer": true` — *"Got It!"*), chapter and overall mastery percentages increase:

```bash
curl -s -X POST http://localhost:8000/api/v1/pipeline/runs/run-halloween-2026/chapters/pumpkin_carving/flip-cards/answer \
  -H "Content-Type: application/json" \
  -d '{
    "card_id": "card_carving_1",
    "knew_answer": true
  }' | python3 -m json.tool
```

#### 5. Submit a Feynman Rubber-Duck Voice Check

Finally, the developer explains the subsystem out loud in their own words. The backend grades their transcript against the chapter's `required_concepts_for_feynman`, returns a `comprehension_score` (0–100), lists `matched_concepts` and `missing_concepts`, and provides a Socratic reply from the Rubber Duck:

```bash
curl -s -X POST http://localhost:8000/api/v1/pipeline/runs/run-halloween-2026/chapters/pumpkin_carving/feynman-voice \
  -H "Content-Type: application/json" \
  -d '{
    "spoken_transcript": "We use an idempotency key cache so network retries never carve the same pumpkin twice, a token bucket rate limiter for backpressure when requests spike, and a circuit breaker that trips open if laser hardware failures exceed the threshold.",
    "audio_duration_seconds": 18.5
  }' | python3 -m json.tool
```

Example response:

```json
{
  "chapter_id": "pumpkin_carving",
  "comprehension_score": 100,
  "passed": true,
  "matched_concepts": [
    "idempotency",
    "token bucket",
    "backpressure",
    "circuit breaker"
  ],
  "missing_concepts": [],
  "rubber_duck_reply": "Quack-tastic! You nailed every core architectural invariant of the Pumpkin Carving Dispatcher.",
  "socratic_follow_up": null,
  "chapter_mastery_percentage": 100,
  "overall_mastery_percentage": 25,
  "ready_to_merge_pr": false
}
```
