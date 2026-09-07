"""Append one entry to data/runs.json from the JSON that `claude -p --output-format json` printed.

Usage: python scripts/record-run.py <claude-output.json> <started-iso> <exit-code>
Keeps the last 200 runs. A broken output file still records the run, marked as an error.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUNS = ROOT / "data" / "runs.json"
KEEP = 200


def parse_output(out_path):
    raw = Path(out_path).read_text(encoding="utf-8", errors="replace")
    # claude may print non-JSON lines first; take the last line that parses as an object.
    for line in reversed(raw.splitlines()):
        line = line.strip()
        if line.startswith("{"):
            try:
                return json.loads(line)
            except json.JSONDecodeError:
                continue
    return json.loads(raw)


def main(out_path, started, exit_code):
    code = int(exit_code)
    entry = {
        "startedAt": started,
        "exitCode": code,
        "durationSec": None,
        "apiSec": None,
        "turns": None,
        "costUsd": None,
        "inputTokens": None,
        "outputTokens": None,
        "isError": code != 0,
        "result": "",
    }
    try:
        data = parse_output(out_path)
        usage = data.get("usage") or {}
        entry.update({
            "durationSec": round((data.get("duration_ms") or 0) / 1000, 1),
            "apiSec": round((data.get("duration_api_ms") or 0) / 1000, 1),
            "turns": data.get("num_turns"),
            "costUsd": data.get("total_cost_usd"),
            "inputTokens": (usage.get("input_tokens") or 0)
            + (usage.get("cache_read_input_tokens") or 0)
            + (usage.get("cache_creation_input_tokens") or 0),
            "outputTokens": usage.get("output_tokens"),
            "isError": bool(data.get("is_error")) or code != 0,
            "result": (data.get("result") or "")[:600],
        })
    except Exception as exc:  # noqa: BLE001
        entry["result"] = f"could not parse claude output: {exc}"
        entry["isError"] = True

    runs = []
    if RUNS.exists():
        try:
            runs = json.loads(RUNS.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            runs = []
    runs.append(entry)
    runs = runs[-KEEP:]
    RUNS.write_text(json.dumps(runs, indent=2), encoding="utf-8")
    print(f"recorded run: {entry['durationSec']}s, {entry['turns']} turns, ${entry['costUsd']}")


if __name__ == "__main__":
    main(*sys.argv[1:4])
