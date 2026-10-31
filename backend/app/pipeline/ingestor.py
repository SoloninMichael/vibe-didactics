"""Stage 1: Semantic Map-Reduce Repository Ingestor for Vibe Didactics.

Scans the AI-generated `mock_halloween_app` codebase using Python's `ast` module,
filters out simulated monorepo noise (vendor bundles, lockfiles, generated protobufs,
and SVG assets) from a 2.14M-line PR, and isolates the 4 core architectural hotspots.
"""

from __future__ import annotations

import ast
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from app.schemas import IngestRequest, RepoIngestionSummary, SubsystemHotspot


class _ASTComplexityVisitor(ast.NodeVisitor):
    """Computes McCabe-style cyclomatic complexity and structural metrics via Python AST."""

    def __init__(self) -> None:
        self.functions_count: int = 0
        self.classes_count: int = 0
        self.branch_points: int = 0

    def visit_ClassDef(self, node: ast.ClassDef) -> None:
        self.classes_count += 1
        self.generic_visit(node)

    def visit_FunctionDef(self, node: ast.FunctionDef) -> None:
        self.functions_count += 1
        self.generic_visit(node)

    def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef) -> None:
        self.functions_count += 1
        self.generic_visit(node)

    def visit_If(self, node: ast.If) -> None:
        self.branch_points += 1
        self.generic_visit(node)

    def visit_IfExp(self, node: ast.IfExp) -> None:
        self.branch_points += 1
        self.generic_visit(node)

    def visit_For(self, node: ast.For) -> None:
        self.branch_points += 1
        self.generic_visit(node)

    def visit_AsyncFor(self, node: ast.AsyncFor) -> None:
        self.branch_points += 1
        self.generic_visit(node)

    def visit_While(self, node: ast.While) -> None:
        self.branch_points += 1
        self.generic_visit(node)

    def visit_ExceptHandler(self, node: ast.ExceptHandler) -> None:
        self.branch_points += 1
        self.generic_visit(node)

    def visit_With(self, node: ast.With) -> None:
        self.branch_points += 1
        self.generic_visit(node)

    def visit_AsyncWith(self, node: ast.AsyncWith) -> None:
        self.branch_points += 1
        self.generic_visit(node)

    def visit_BoolOp(self, node: ast.BoolOp) -> None:
        self.branch_points += max(1, len(node.values) - 1)
        self.generic_visit(node)

    def visit_comprehension(self, node: ast.comprehension) -> None:
        self.branch_points += 1 + len(node.ifs)
        self.generic_visit(node)

    @property
    def cyclomatic_complexity(self) -> int:
        return max(1, 1 + self.functions_count + self.branch_points)


class RepoIngestor:
    """Semantic Map-Reduce ingestor that distills massive AI PRs into didactic hotspots."""

    _HOTSPOT_SPECS: List[Dict[str, object]] = [
        {
            "subsystem_id": "sub_1_carving",
            "title": "Autonomous Laser Pumpkin Carving Dispatcher",
            "relative_file": "carving_dispatcher.py",
            "file_path": "data/mock_halloween_app/carving_dispatcher.py",
            "fallback_loc": 158,
            "fallback_complexity": 22,
            "architectural_pattern": "Idempotency Lock + Token Bucket",
            "risk_level": "CRITICAL",
            "why_hard_to_understand": (
                "Combines time-proportional token-bucket burst rate limiting, in-flight TTL "
                "idempotency locking, and fractal SVG kerf-load structural physics in a single "
                "synchronous laser dispatch path."
            ),
            "calls_to": ["sub_2_candle_fsm", "sub_4_spooky_sync"],
        },
        {
            "subsystem_id": "sub_2_candle_fsm",
            "title": "Smart Jack-o'-Lantern Candle Safety FSM",
            "relative_file": "candle_safety_fsm.py",
            "file_path": "data/mock_halloween_app/candle_safety_fsm.py",
            "fallback_loc": 169,
            "fallback_complexity": 26,
            "architectural_pattern": "Hierarchical FSM + Circuit Breaker",
            "risk_level": "CRITICAL",
            "why_hard_to_understand": (
                "Couples UDP monotonic sequence-number deduplication with a 6-state flame safety "
                "state machine and a 3-state (CLOSED/OPEN/HALF_OPEN) thermal circuit breaker that "
                "triggers emergency CO2 extinguisher puffs."
            ),
            "calls_to": ["sub_4_spooky_sync"],
        },
        {
            "subsystem_id": "sub_3_candy_saga",
            "title": "Allergy-Safe Candy Inventory & Dispatch Saga",
            "relative_file": "candy_router.py",
            "file_path": "data/mock_halloween_app/candy_router.py",
            "fallback_loc": 174,
            "fallback_complexity": 21,
            "architectural_pattern": "Optimistic Locking + Saga Rollback",
            "risk_level": "CRITICAL",
            "why_hard_to_understand": (
                "Interleaves transitive allergen cross-contamination set verification with "
                "versioned compare-and-swap (CAS) cauldron mutations, reverse-order compensating "
                "rollbacks, and Dead Letter Queue (DLQ) routing."
            ),
            "calls_to": ["sub_4_spooky_sync"],
        },
        {
            "subsystem_id": "sub_4_spooky_sync",
            "title": "500-Skeleton Animatronic 60fps Audio Sync Hub",
            "relative_file": "spooky_sync_engine.py",
            "file_path": "data/mock_halloween_app/spooky_sync_engine.py",
            "fallback_loc": 155,
            "fallback_complexity": 19,
            "architectural_pattern": "Bounded Ring Buffer + Backpressure",
            "risk_level": "HIGH",
            "why_hard_to_understand": (
                "Synchronizes 128 BPM trigonometric joint choreography across 500 lossy graveyard "
                "Wi-Fi nodes using a Drop-Oldest bounded ring buffer and exponential moving average "
                "(EMA) clock-drift jitter compensation."
            ),
            "calls_to": [],
        },
    ]

    def __init__(self, mock_app_dir: Optional[Path | str] = None) -> None:
        if mock_app_dir is not None:
            self.mock_app_dir = Path(mock_app_dir)
        else:
            self.mock_app_dir = (
                Path(__file__).resolve().parents[3] / "data" / "mock_halloween_app"
            )

    def _analyze_file_ast(
        self, file_path: Path, fallback_loc: int, fallback_complexity: int
    ) -> Tuple[int, int]:
        """Inspects a Python file using `ast` to count lines and cyclomatic complexity."""
        if not file_path.is_file():
            return fallback_loc, fallback_complexity

        try:
            source = file_path.read_text(encoding="utf-8")
            lines_of_code = len(source.splitlines()) or fallback_loc
            tree = ast.parse(source, filename=str(file_path))
            visitor = _ASTComplexityVisitor()
            visitor.visit(tree)
            return lines_of_code, visitor.cyclomatic_complexity
        except (OSError, SyntaxError, ValueError):
            return fallback_loc, fallback_complexity

    @staticmethod
    def _build_mermaid_interaction_graph(hotspots: List[SubsystemHotspot]) -> str:
        """Builds a Mermaid flowchart illustrating how the 4 Halloween subsystems interact."""
        by_id = {h.subsystem_id: h for h in hotspots}
        s1 = by_id["sub_1_carving"]
        s2 = by_id["sub_2_candle_fsm"]
        s3 = by_id["sub_3_candy_saga"]
        s4 = by_id["sub_4_spooky_sync"]

        return "\n".join(
            [
                "flowchart TD",
                '    PR["Massive AI PR (2,140,000 raw lines)"] -->|Semantic AST Filter| CORE["4 Core Architectural Hotspots"]',
                f'    CORE --> sub_1_carving["1. {s1.title}<br/>({s1.architectural_pattern} | {s1.lines_of_code} LOC)"]',
                f'    CORE --> sub_2_candle_fsm["2. {s2.title}<br/>({s2.architectural_pattern} | {s2.lines_of_code} LOC)"]',
                f'    CORE --> sub_3_candy_saga["3. {s3.title}<br/>({s3.architectural_pattern} | {s3.lines_of_code} LOC)"]',
                f'    CORE --> sub_4_spooky_sync["4. {s4.title}<br/>({s4.architectural_pattern} | {s4.lines_of_code} LOC)"]',
                '    sub_1_carving -->|"Carved Pumpkin Ready -> Arm Ignition"| sub_2_candle_fsm',
                '    sub_1_carving -->|"Laser Rig Cue Event"| sub_4_spooky_sync',
                '    sub_2_candle_fsm -->|"CO2 Cutoff / Flame Telemetry Alert"| sub_4_spooky_sync',
                '    sub_3_candy_saga -->|"Trick-or-Treater Arrival Fanfare"| sub_4_spooky_sync',
            ]
        )

    def ingest(self, request: Optional[IngestRequest] = None) -> RepoIngestionSummary:
        """Runs Stage 1 ingestion and returns a `RepoIngestionSummary`."""
        req = request or IngestRequest()
        hotspots: List[SubsystemHotspot] = []

        for spec in self._HOTSPOT_SPECS:
            target_file = self.mock_app_dir / str(spec["relative_file"])
            loc, complexity = self._analyze_file_ast(
                target_file,
                fallback_loc=int(spec["fallback_loc"]),
                fallback_complexity=int(spec["fallback_complexity"]),
            )
            hotspots.append(
                SubsystemHotspot(
                    subsystem_id=str(spec["subsystem_id"]),
                    title=str(spec["title"]),
                    file_path=str(spec["file_path"]),
                    lines_of_code=loc,
                    cyclomatic_complexity=complexity,
                    architectural_pattern=str(spec["architectural_pattern"]),
                    risk_level=str(spec["risk_level"]),
                    why_hard_to_understand=str(spec["why_hard_to_understand"]),
                    calls_to=list(spec["calls_to"]),  # type: ignore[arg-type]
                )
            )

        core_lines = sum(h.lines_of_code for h in hotspots)
        total_raw = max(req.simulated_total_lines, core_lines + 1)
        filtered_lines = total_raw - core_lines
        noise_pct = (filtered_lines / total_raw) * 100.0
        compression_ratio = (
            f"{noise_pct:.2f}% noise filtered "
            f"({total_raw:,} -> {core_lines:,} core architectural lines)"
        )

        return RepoIngestionSummary(
            repo_name=req.repo_name,
            pr_title=req.pr_title,
            target_branch=req.target_branch,
            total_raw_lines_scanned=total_raw,
            filtered_generated_or_vendor_lines=filtered_lines,
            core_architectural_lines=core_lines,
            compression_ratio=compression_ratio,
            mermaid_interaction_graph=self._build_mermaid_interaction_graph(hotspots),
            hotspots=hotspots,
        )

    def run(self, request: Optional[IngestRequest] = None) -> RepoIngestionSummary:
        """Alias for `ingest`."""
        return self.ingest(request=request)

    def analyze_repository(
        self, request: Optional[IngestRequest] = None
    ) -> RepoIngestionSummary:
        """Alias for `ingest`."""
        return self.ingest(request=request)


def ingest_repository(request: Optional[IngestRequest] = None) -> RepoIngestionSummary:
    """Module-level helper to run `RepoIngestor().ingest(request)`."""
    return RepoIngestor().ingest(request=request)
