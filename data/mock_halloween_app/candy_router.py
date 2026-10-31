"""Subsystem 3: Distributed Candy Inventory & Allergy-Safe Dispatch Router.

Implements allergy cross-contamination filtering, Optimistic Concurrency Control
(compare-and-swap via version counters) for cauldron inventory across neighborhood
houses, and a Saga pattern with reverse-order compensating rollbacks and Dead
Letter Queue (DLQ) routing when multi-SKU trick-or-treater bag reservations fail.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Dict, List, Optional, Set, Tuple

from .models import AllergyTag, CandySkuBatch, TrickOrTreaterOrder


class CandyDispatchError(Exception):
    """Base exception for candy routing and reservation failures."""


class AllergyContaminationError(CandyDispatchError):
    """Raised when a candy SKU contains allergens conflicting with a kid's profile."""


class StockDepletionError(CandyDispatchError):
    """Raised when a cauldron lacks sufficient units of a requested candy SKU."""


class VersionConflictError(CandyDispatchError):
    """Raised when an Optimistic Concurrency Control (CAS) version check fails."""


@dataclass
class DeadLetterEntry:
    """Record routed to the Dead Letter Queue (DLQ) for manual cauldron refill."""

    order: TrickOrTreaterOrder
    failed_sku_id: str
    reason: str
    rolled_back_skus: List[Tuple[str, int]]
    timestamp: datetime = field(default_factory=datetime.utcnow)


@dataclass
class SagaDispatchReceipt:
    """Outcome of a CandyDispatchSaga execution for a trick-or-treater order."""

    kid_id: str
    dispatched: bool
    reserved_items: Dict[str, int]
    rollback_log: List[str] = field(default_factory=list)
    failure_reason: Optional[str] = None


class AllergyGuardFilter:
    """Verifies zero allergen cross-contamination before candy leaves the cauldron."""

    def __init__(self, shared_chute_traces: Optional[Dict[str, Set[AllergyTag]]] = None) -> None:
        self._shared_chute_traces: Dict[str, Set[AllergyTag]] = shared_chute_traces or {}

    def is_safe(self, order: TrickOrTreaterOrder, batch: CandySkuBatch) -> bool:
        """Return True if neither batch allergens nor factory traces intersect kid allergies."""
        batch_allergens = set(batch.allergens) | self._shared_chute_traces.get(batch.sku_id, set())
        return set(order.allergies).isdisjoint(batch_allergens)

    def verify_safe(self, order: TrickOrTreaterOrder, batch: CandySkuBatch) -> None:
        """Raise AllergyContaminationError if any direct or trace allergen intersects."""
        batch_allergens = set(batch.allergens) | self._shared_chute_traces.get(batch.sku_id, set())
        conflicts = set(order.allergies).intersection(batch_allergens)
        if conflicts:
            conflict_names = ", ".join(sorted(tag.value for tag in conflicts))
            raise AllergyContaminationError(
                f"Allergy conflict for kid '{order.kid_id}' ({order.costume_name}) "
                f"on SKU '{batch.sku_id}' ({batch.candy_name}): [{conflict_names}]"
            )


class CandyInventoryStore:
    """Cauldron inventory store guarded by Optimistic Concurrency Control (CAS)."""

    def __init__(self, initial_batches: Optional[List[CandySkuBatch]] = None) -> None:
        self._cauldron: Dict[str, CandySkuBatch] = {
            batch.sku_id: batch for batch in (initial_batches or [])
        }

    def get_batch(self, sku_id: str) -> CandySkuBatch:
        if sku_id not in self._cauldron:
            raise StockDepletionError(f"Unknown candy SKU '{sku_id}' not in cauldron.")
        return self._cauldron[sku_id]

    def reserve_cas(self, sku_id: str, quantity: int, expected_version: int) -> int:
        """Atomically decrement inventory if version matches expected_version (CAS)."""
        batch = self.get_batch(sku_id)
        if batch.version != expected_version:
            raise VersionConflictError(
                f"CAS version mismatch on '{sku_id}': expected v{expected_version}, "
                f"found v{batch.version} due to concurrent house dispatch."
            )
        if batch.available_units < quantity:
            raise StockDepletionError(
                f"Cauldron depleted for '{sku_id}': requested {quantity}, "
                f"available {batch.available_units}."
            )
        batch.available_units -= quantity
        batch.version += 1
        return batch.version

    def compensate_return(self, sku_id: str, quantity: int) -> int:
        """Compensating transaction: return reserved candy back to the cauldron."""
        batch = self.get_batch(sku_id)
        batch.available_units += quantity
        batch.version += 1
        return batch.version


class CandyDispatchSaga:
    """Coordinates multi-SKU bag reservation with reverse-order compensating rollbacks."""

    def __init__(
        self,
        inventory: CandyInventoryStore,
        allergy_guard: Optional[AllergyGuardFilter] = None,
    ) -> None:
        self.inventory = inventory
        self.allergy_guard = allergy_guard or AllergyGuardFilter()
        self.dead_letter_queue: List[DeadLetterEntry] = []

    def execute_order(
        self,
        order: TrickOrTreaterOrder,
        version_overrides: Optional[Dict[str, int]] = None,
    ) -> SagaDispatchReceipt:
        """Reserve all requested candy SKUs or roll back in reverse order on failure."""
        committed_steps: List[Tuple[str, int]] = []
        rollback_log: List[str] = []
        overrides = version_overrides or {}

        for sku_id, quantity in order.requested_candy_skus.items():
            try:
                batch = self.inventory.get_batch(sku_id)
                self.allergy_guard.verify_safe(order, batch)
                expected_ver = overrides.get(sku_id, batch.version)
                self.inventory.reserve_cas(sku_id, quantity, expected_version=expected_ver)
                committed_steps.append((sku_id, quantity))
            except CandyDispatchError as exc:
                for prev_sku, prev_qty in reversed(committed_steps):
                    new_ver = self.inventory.compensate_return(prev_sku, prev_qty)
                    rollback_log.append(f"Returned {prev_qty}x '{prev_sku}' to cauldron (v{new_ver})")
                self.dead_letter_queue.append(
                    DeadLetterEntry(order, sku_id, str(exc), list(reversed(committed_steps)))
                )
                return SagaDispatchReceipt(order.kid_id, False, {}, rollback_log, str(exc))

        return SagaDispatchReceipt(order.kid_id, True, dict(committed_steps))
