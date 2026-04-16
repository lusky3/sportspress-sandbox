# SportsPress Test Framework

LLM-agent-driven testing for the SportsPress WordPress plugin using Playwright MCP.

## Overview

An LLM agent connects to a Playwright MCP server, reads human-readable test suites (Markdown), executes them against a live WordPress instance, and produces structured JSON results. Helper scripts handle state reset, orchestration, and report conversion.

## Directory Structure

```
tests/
├── README.md              # This file
├── reset-state.sh         # Reset DB to baseline between suites
├── run-suite.sh           # Orchestrate suite execution
├── report-converter.js    # Convert JSON results → JUnit XML
├── suites/                # Test suite definitions (.md)
│   ├── 00-smoke.md
│   └── ...
└── results/               # Timestamped output directories (git-ignored)
    └── 20260416T144600/
        ├── 00-smoke.md
        └── 00-smoke.json
```

## Running Tests

### Manual (single suite)

```bash
./tests/run-suite.sh tests/suites/00-smoke.md
```

### All suites

```bash
./tests/run-suite.sh all
```

The runner resets WordPress state before each suite, creates a timestamped results directory, and prints a summary.

### State Reset Only

```bash
./tests/reset-state.sh
```

Works from the host (uses `docker exec`) or inside the container.

## Writing New Test Suites

1. Create a Markdown file in `tests/suites/` with a numeric prefix for ordering (e.g., `05-leagues.md`).
2. Structure the file with a title, preconditions, and numbered test steps:

```markdown
# Suite: League Management

## Preconditions
- SportsPress plugin is active
- At least one sport is configured

## Tests

### TEST-01: Create a league
1. Navigate to SportsPress → Leagues
2. Click "Add New"
3. Enter name "Test League"
4. Click "Add New League"
5. **Expected:** League appears in the list
```

3. Each test should have a clear expected outcome the agent can verify.

## Test Result Format

The agent produces a JSON file per suite:

```json
{
  "testSuite": "00-smoke",
  "timestamp": "2026-04-16T14:46:00.000Z",
  "tests": [
    {
      "id": "SMOKE-01",
      "name": "WordPress loads",
      "category": "smoke",
      "status": "passed",
      "duration_ms": 1200
    },
    {
      "id": "SMOKE-02",
      "name": "Admin login works",
      "category": "smoke",
      "status": "failed",
      "duration_ms": 3400,
      "error": "Login page returned 500",
      "screenshot": "/screenshots/smoke-02-error.png"
    }
  ]
}
```

### Field Reference

| Field         | Type   | Required | Description                          |
|---------------|--------|----------|--------------------------------------|
| `testSuite`   | string | yes      | Suite identifier                     |
| `timestamp`   | string | yes      | ISO-8601 execution timestamp         |
| `tests`       | array  | yes      | Array of test result objects         |
| `tests[].id`  | string | yes      | Unique test identifier               |
| `tests[].name`| string | yes      | Human-readable test name             |
| `tests[].category` | string | yes | Test category / grouping            |
| `tests[].status` | string | yes   | `passed`, `failed`, or `skipped`     |
| `tests[].duration_ms` | number | yes | Execution time in milliseconds    |
| `tests[].error` | string | no     | Error message (when failed)          |
| `tests[].screenshot` | string | no | Path to failure screenshot          |

## Report Conversion

Convert JSON results to JUnit XML for CI integration:

```bash
# stdin/stdout
cat tests/results/*/00-smoke.json | node tests/report-converter.js

# file arguments
node tests/report-converter.js results/00-smoke.json report.xml
```

## Troubleshooting

- **`baseline.sql not found`** — The container needs a baseline dump at `/var/lib/baseline/baseline.sql`. Run `wp db export /var/lib/baseline/baseline.sql --allow-root` inside the container after initial setup.
- **State reset fails** — Ensure the `sportspress-test` container is running: `docker compose ps`.
- **No results JSON** — The LLM agent writes results asynchronously. Check that the agent completed its run and wrote to the correct results directory.
- **Permission denied on scripts** — Run `chmod +x tests/reset-state.sh tests/run-suite.sh`.
