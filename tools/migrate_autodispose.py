#!/usr/bin/env python3
"""Convert screen-scoped Riverpod providers to .autoDispose variants.

Scope:
  - Targets only lib/features/**/providers/*.dart
  - Converts FutureProvider, StreamProvider, StateNotifierProvider
    (including .family) to their .autoDispose forms.
  - Leaves plain Provider<T> alone (those are repository singletons).
  - Leaves StateProvider alone (often global UI state — case-by-case).
  - Skips files under lib/features/auth/ entirely (auth state must persist).
  - Skips a file if it has a top-of-file comment // perf:keep-alive
    so callers can opt out per-file.
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PROVIDERS_GLOB = REPO / "lib" / "features"

SKIP_DIRS = (
    "auth",  # whole auth subtree — session-wide state
)
SKIP_FILE_MARKER = "// perf:keep-alive"

# (pattern, replacement) — applied as plain string replace.
# Order matters: longer + more-specific patterns first.
REPLACEMENTS: list[tuple[str, str]] = [
    ("FutureProvider.family<", "FutureProvider.autoDispose.family<"),
    ("StreamProvider.family<", "StreamProvider.autoDispose.family<"),
    ("StateNotifierProvider.family<", "StateNotifierProvider.autoDispose.family<"),
    ("FutureProvider<", "FutureProvider.autoDispose<"),
    ("StreamProvider<", "StreamProvider.autoDispose<"),
    ("StateNotifierProvider<", "StateNotifierProvider.autoDispose<"),
]


def should_skip(p: Path) -> bool:
    parts = p.relative_to(REPO).parts
    for d in SKIP_DIRS:
        if d in parts:
            return True
    return False


def already_autodispose(s: str, base: str) -> bool:
    # Avoid double-conversion if file already has autoDispose form.
    return f"{base}.autoDispose" in s


def transform(text: str) -> tuple[str, int]:
    count = 0
    new = text
    for pat, rep in REPLACEMENTS:
        # Idempotency guard: skip if already converted.
        # Each pattern check naturally avoids creating .autoDispose.autoDispose
        # because we don't match the replacement string in the source.
        if pat not in new:
            continue
        before = new.count(pat)
        # But be careful: replacing "FutureProvider<" might also match inside
        # "FutureProvider.autoDispose<" — it won't, because after .autoDispose
        # the bracket is at a different position. Verified by inspection.
        new = new.replace(pat, rep)
        count += before
    return new, count


def main() -> int:
    if not PROVIDERS_GLOB.exists():
        print(f"Path not found: {PROVIDERS_GLOB}")
        return 1
    files = sorted(PROVIDERS_GLOB.rglob("providers/*.dart"))
    total = 0
    converted_files = 0
    for p in files:
        if should_skip(p):
            print(f"SKIP {p.relative_to(REPO)}  (auth subtree)")
            continue
        original = p.read_text()
        if SKIP_FILE_MARKER in original.splitlines()[:5] if len(original.splitlines()) >= 5 else []:
            print(f"SKIP {p.relative_to(REPO)}  (// perf:keep-alive)")
            continue
        new, n = transform(original)
        if n == 0:
            continue
        p.write_text(new)
        print(f"OK   {p.relative_to(REPO)}  ({n} converted)")
        total += n
        converted_files += 1
    print(f"\nConverted {total} provider declarations across {converted_files} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
