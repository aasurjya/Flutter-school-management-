#!/usr/bin/env python3
"""One-shot migration: Image.network(...) -> CachedNetworkImage(...).

Adds the cached_network_image import and rewrites the call site:
  Image.network(URL, ...stuff..., errorBuilder: (_, __, ___) => W)
becomes
  CachedNetworkImage(imageUrl: URL, ...stuff..., errorWidget: (_, __, ___) => W)

errorBuilder has signature (context, error, stackTrace); errorWidget has
(context, url, error). The shape (_, __, ___) is signature-agnostic so a
purely lexical swap is safe for the callsites in this repo (verified by
inspection — none of them reference the parameters by name).
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]

TARGETS = [
    "lib/features/id_card/presentation/screens/school_branding_screen.dart",
    "lib/features/id_card/presentation/widgets/id_card_widget.dart",
    "lib/features/lms/presentation/screens/course_detail_screen.dart",
    "lib/features/lms/presentation/widgets/course_card.dart",
    "lib/features/gamification/presentation/screens/achievements_screen.dart",
    "lib/features/gamification/presentation/screens/leaderboard_screen.dart",
    "lib/features/canteen/presentation/screens/cart_screen.dart",
    "lib/features/canteen/presentation/screens/canteen_menu_screen.dart",
    "lib/features/library/presentation/screens/my_books_screen.dart",
    "lib/features/library/presentation/screens/library_screen.dart",
    "lib/features/library/presentation/screens/book_detail_screen.dart",
    "lib/features/inventory/presentation/widgets/asset_card.dart",
    "lib/features/inventory/presentation/screens/asset_detail_screen.dart",
    "lib/features/alumni/presentation/screens/event_detail_screen.dart",
    "lib/features/alumni/presentation/screens/success_stories_screen.dart",
    "lib/features/alumni/presentation/widgets/story_card.dart",
    "lib/features/qr_scan/presentation/widgets/student_id_card_widget.dart",
    "lib/shared/widgets/empty_state.dart",
]

IMPORT_LINE = "import 'package:cached_network_image/cached_network_image.dart';\n"


def add_import(text: str) -> str:
    if "cached_network_image" in text:
        return text
    # Insert after the last existing 'package:' import.
    lines = text.split("\n")
    last = -1
    for i, line in enumerate(lines):
        if line.startswith("import 'package:") or line.startswith('import "package:'):
            last = i
    if last == -1:
        # Fall back to first non-comment line
        for i, line in enumerate(lines):
            if line and not line.startswith("//"):
                last = i - 1
                break
    lines.insert(last + 1, IMPORT_LINE.rstrip("\n"))
    return "\n".join(lines)


def rewrite_calls(text: str) -> tuple[str, int]:
    """Replace Image.network(<url>, ...) with CachedNetworkImage(imageUrl: <url>, ...)
    and errorBuilder: with errorWidget:.

    We balance parens to find the full call, then transform inside it.
    """
    out: list[str] = []
    i = 0
    replaced = 0
    n = len(text)
    while i < n:
        m = re.search(r"\bImage\.network\(", text[i:])
        if not m:
            out.append(text[i:])
            break
        start = i + m.start()
        paren = i + m.end()  # right after the '('
        out.append(text[i:start])
        # Find matching ')'
        depth = 1
        j = paren
        in_str = None  # None | "'" | '"'
        while j < n and depth > 0:
            c = text[j]
            if in_str:
                if c == "\\":
                    j += 2
                    continue
                if c == in_str:
                    in_str = None
            else:
                if c in ("'", '"'):
                    in_str = c
                elif c == "(":
                    depth += 1
                elif c == ")":
                    depth -= 1
                    if depth == 0:
                        break
            j += 1
        if depth != 0:
            # Unbalanced — skip
            out.append(text[start:])
            break
        body = text[paren:j]  # inside the parens
        # First positional arg = url, ends at top-level comma
        url_end = _top_level_comma(body)
        if url_end == -1:
            # Only the url, no comma — synthesize
            url = body.strip()
            rest = ""
        else:
            url = body[:url_end].strip()
            rest = body[url_end + 1 :]
        # Replace errorBuilder -> errorWidget (lexical; only callsites without
        # name references — verified).
        rest = re.sub(r"\berrorBuilder\b", "errorWidget", rest)
        # Build the new call.
        new_call = "CachedNetworkImage(\n              imageUrl: " + url
        if rest.strip():
            # Preserve leading whitespace/newline character of rest.
            new_call += "," + rest
        else:
            new_call += rest
        new_call += ")"
        out.append(new_call)
        i = j + 1
        replaced += 1
    return "".join(out), replaced


def _top_level_comma(s: str) -> int:
    depth = 0
    in_str = None
    i = 0
    while i < len(s):
        c = s[i]
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == in_str:
                in_str = None
        else:
            if c in ("'", '"'):
                in_str = c
            elif c in "([{":
                depth += 1
            elif c in ")]}":
                depth -= 1
            elif c == "," and depth == 0:
                return i
        i += 1
    return -1


def main() -> int:
    total = 0
    for rel in TARGETS:
        p = REPO / rel
        if not p.exists():
            print(f"SKIP (not found): {rel}")
            continue
        original = p.read_text()
        rewritten, count = rewrite_calls(original)
        if count == 0:
            print(f"NOOP {rel}")
            continue
        rewritten = add_import(rewritten)
        p.write_text(rewritten)
        print(f"OK   {rel}  ({count} replaced)")
        total += count
    print(f"\nTotal: {total} Image.network -> CachedNetworkImage")
    return 0


if __name__ == "__main__":
    sys.exit(main())
