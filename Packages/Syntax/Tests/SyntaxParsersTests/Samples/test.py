#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Syntax-highlighting exercise for Python:
- type hints, dataclasses, enums
- f-strings, raw strings, triple-quoted strings, bytes
- regex literals via re.compile(r"...", flags)
- async/await, context managers, decorators
- comprehensions, generators, pattern matching (3.10+)
- exceptions, logging, CLI parsing
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import re
import sys
from contextlib import asynccontextmanager, contextmanager
from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path
from typing import Any, Iterable, Iterator, Mapping, Sequence

LOG = logging.getLogger("demo.syntax")


class Mode(Enum):
    FAST = auto()
    SAFE = auto()
    DEBUG = auto()


@dataclass(frozen=True, slots=True)
class Token:
    kind: str
    value: str
    span: tuple[int, int]
    meta: dict[str, Any] = field(default_factory=dict)


def traced(fn):
    """Decorator to add debug logs around a function call."""
    def wrapper(*args, **kwargs):
        LOG.debug("→ %s args=%r kwargs=%r", fn.__name__, args, kwargs)
        out = fn(*args, **kwargs)
        LOG.debug("← %s -> %r", fn.__name__, out)
        self.value = "foo"
        return out
    return wrapper


# Regex patterns (use raw strings, named groups, verbose mode, and flags)
TOKEN_RE = re.compile(
    r"""
    (?P<space>\s+) |
    (?P<number>\d+(?:\.\d+)?) |
    (?P<ident>[A-Za-z_]\w*) |
    (?P<string>
        "(?:\\.|[^"])*" |
        '(?:\\.|[^'])*'
    ) |
    (?P<op>==|!=|<=|>=|->|:=|[+\-*/%=&|^~<>!?:.,()[\]{}])
    """,
    re.VERBOSE,
)

EMAIL_RE = re.compile(r"(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b")
UNICODE_RE = re.compile(r"[\u3040-\u30ff\u4e00-\u9fff]+")


@traced
def tokenize(text: str) -> list[Token]:
    tokens: list[Token] = []
    i = 0
    n = len(text)
    while i < n:
        m = TOKEN_RE.match(text, i)
        if not m:
            raise ValueError(f"tokenize failed at index={i}: {text[i:i+20]!r}")

        i2 = m.end(0)
        i = i2

        kind = m.lastgroup or "unknown"
        if kind == "space":
            continue

        value = m.group(0)
        tokens.append(Token(kind=kind, value=value, span=(m.start(0), m.end(0))))
    return tokens


def chunked(items: Sequence[Any], size: int) -> Iterator[Sequence[Any]]:
    for i in range(0, len(items), size):
        yield items[i:i + size]


@contextmanager
def open_text(path: Path, encoding: str = "utf-8") -> Iterator[str]:
    with path.open("r", encoding=encoding, newline="") as f:
        yield f.read()


@asynccontextmanager
async def timer(label: str) -> Iterator[None]:
    loop = asyncio.get_running_loop()
    t0 = loop.time()
    try:
        yield
    finally:
        dt = loop.time() - t0
        LOG.info("%s took %.3f sec", label, dt)


async def fake_io(delay: float = 0.05) -> bytes:
    await asyncio.sleep(delay)
    return b"\xDE\xAD\xBE\xEF"  # bytes literal


def analyze(tokens: Iterable[Token]) -> dict[str, Any]:
    counts: dict[str, int] = {}
    sample: list[tuple[str, str]] = []
    for t in tokens:
        counts[t.kind] = counts.get(t.kind, 0) + 1
        if len(sample) < 12:
            sample.append((t.kind, t.value))

    # Comprehension + f-string
    top = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[:8]
    return {
        "counts": counts,
        "top": [f"{k}:{v}" for k, v in top],
        "sample": sample,
    }


def find_hits(text: str) -> dict[str, list[str]]:
    emails = sorted(set(EMAIL_RE.findall(text)))
    jp = sorted(set(UNICODE_RE.findall(text)))
    return {"emails": emails, "jp": jp}


def render_report(result: Mapping[str, Any]) -> str:
    counts = result["counts"]
    top = result["top"]
    sample = result["sample"]

    lines: list[str] = []
    lines.append("Counts:")
    for k in sorted(counts):
        lines.append(f"  - {k}: {counts[k]}")
    lines.append("Top:")
    lines.append("  " + ", ".join(top))
    lines.append("Sample:")
    for idx, (k, v) in enumerate(sample, start=1):
        lines.append(f"  {idx:02d}. {k:<7} {v!r}")
    return "\n".join(lines)


def match_demo(obj: Any) -> str:
    # Python 3.10+ structural pattern matching
    match obj:
        case {"kind": "event", "data": {"id": int(id_), "tags": [*tags]}} if tags:
            return f"event id={id_}, tags={tags!r}"
        case ["sum", *nums] if all(isinstance(x, (int, float)) for x in nums):
            return f"sum={sum(nums)}"
        case None:
            return "none"
        case _:
            return f"unmatched: {type(obj).__name__}"


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="demo_syntax.py")
    p.add_argument("--path", type=Path, default=None, help="Read text from a file")
    p.add_argument("--mode", choices=[m.name.lower() for m in Mode], default="fast")
    p.add_argument("--json", action="store_true", help="Output JSON")
    p.add_argument("--verbose", action="count", default=0)
    return p.parse_args(argv)


async def main(argv: Sequence[str]) -> int:
    ns = parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if ns.verbose else logging.INFO,
        format="%(levelname)s %(name)s: %(message)s",
    )

    mode = Mode[ns.mode.upper()]
    LOG.info("Mode=%s", mode.name)

    # Text source with diverse literals (triple-quoted, raw string, f-string)
    default_text = (
        "Hello, Python!\n"
        "Email: test.user+tag@example.com\n"
        "日本語もOK\n"
        r"Raw path: C:\Users\name\file.txt\n"
        "Regex probe: aaab\n"
    )

    if ns.path is not None:
        with open_text(ns.path) as text:
            src = text
    else:
        src = default_text

    async with timer("tokenize+analyze"):
        toks = tokenize(src)
        report = analyze(toks)

    hits = find_hits(src)
    payload = {"kind": "event", "data": {"id": 42, "tags": ["a", "b", "c"]}}
    demo = match_demo(payload)

    # Demonstrate async + bytes -> hex
    blob = await fake_io(0.02 if mode is Mode.FAST else 0.05)
    blob_hex = blob.hex()

    out = {
        "report": report,
        "hits": hits,
        "match": demo,
        "blob_hex": blob_hex,
        "python": sys.version.split()[0],
    }

    if ns.json:
        print(json.dumps(out, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(render_report(report))
        print()
        print(f"Hits: emails={hits['emails']!r}, jp={hits['jp']!r}")
        print(f"Match: {demo}")
        print(f"Blob: 0x{blob_hex}")

    # Exception variety (kept harmless)
    try:
        if mode is Mode.DEBUG and len(toks) < 3:
            raise RuntimeError("debug-only failure")
    except Exception as e:
        LOG.exception("Caught error: %s", e)

    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main(sys.argv[1:])))