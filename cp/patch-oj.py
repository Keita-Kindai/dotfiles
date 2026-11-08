#!/usr/bin/env python3
"""Patch online-judge-api-client so it parses AtCoder's new memory limit format.

AtCoder now prints "1024 MiB" instead of "1024 MB", which makes oj fail with
`assert parsed_memory_limit`. Run this with the Python that oj uses.
Safe to run more than once.
"""
import re
import sys
from pathlib import Path

import onlinejudge.service.atcoder as atcoder

path = Path(atcoder.__file__)
src = path.read_text(encoding="utf-8")

if "KiB" in src:
    print(f"already patched: {path}")
    sys.exit(0)

old = re.compile(
    r"        parsed_memory_limit = re\.search\(r'\^\(メモリ制限\|Memory Limit\): \(\[0-9\.\]\+\) \(KB\|MB\)', memory_limit\)\n"
    r".*?"
    r"            assert False\n",
    re.S,
)
new = (
    "        parsed_memory_limit = re.search(r'^(メモリ制限|Memory Limit): ([0-9.]+) ?([KMG]i?B)', memory_limit)\n"
    "        assert parsed_memory_limit\n"
    "\n"
    "        memory_limit_value = parsed_memory_limit.group(2)\n"
    "        memory_limit_unit = parsed_memory_limit.group(3)\n"
    "        units = {'KB': 10**3, 'MB': 10**6, 'GB': 10**9, 'KiB': 2**10, 'MiB': 2**20, 'GiB': 2**30}\n"
    "        memory_limit_byte = int(float(memory_limit_value) * units[memory_limit_unit])\n"
)
patched, n = old.subn(lambda _: new, src, count=1)
if n != 1:
    sys.exit(f"pattern not found, not patched: {path}")
path.with_suffix(".py.orig").write_text(src, encoding="utf-8")
path.write_text(patched, encoding="utf-8")
print(f"patched: {path}")
