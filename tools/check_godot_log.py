#!/usr/bin/env python3
"""Godot may return success after script errors; reject those logs explicitly."""
import pathlib
import re
import sys
text = pathlib.Path(sys.argv[1]).read_text(errors="replace")
errors = [line for line in text.splitlines() if re.search(r"(?:SCRIPT ERROR:|Parse Error:|^ERROR:)", line)]
if errors:
    print("Godot reported errors:", *errors, sep="\n", file=sys.stderr)
    sys.exit(1)
