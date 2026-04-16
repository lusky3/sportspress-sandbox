# SportsPress Docker Test Environment

Complete WordPress + SportsPress test environment with LLM agent automation support via Playwright MCP.

## Quick Start

```bash
# Build and start all services (waits for healthy)
docker compose up -d --build --wait

# Access points:
# WordPress:      http://localhost:8082       (auto-login enabled)
# Playwright MCP: http://localhost:3000/sse   (LLM agent endpoint)
# REST Health:    http://localhost:8082/wp-json/test/v1/health
# Mailhog:        http://localhost:8025
# Adminer:        http://localhost:8080

# Stop everything
docker compose down -v
```

## Architecture

```text
┌─────────────────────────────────────────────────────┐
│  LLM Agent (Kiro / Claude / GPT)                    │
│  MCP: playwright @ localhost:3000/sse               │
│  HTTP: REST API @ localhost:8082/wp-json/            │
│  Shell: docker exec sportspress-test wp ...          │
└──────────┬──────────────────┬───────────────────────┘
           │ MCP (browser)    │ HTTP + docker exec
           ▼                  ▼
┌──────────────────┐   ┌─────────────────────────────┐
│  playwright       │   │  sportspress-test            │
│  Chromium +       │──▶│  Nginx + PHP-FPM + MariaDB   │
│  MCP Server:3000  │   │  SportsPress + Admin Tools   │
└──────────────────┘   │  WP-CLI + auto-login          │
         └──── Docker Network (sp-test-net) ───────────┘
```

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| sportspress-test | Custom (Alpine + WP) | 8082 | WordPress + SportsPress + MariaDB |
| playwright | mcr.microsoft.com/playwright:v1.52.0-noble | 3000 | Browser automation MCP server |
| mailhog | mailhog/mailhog | 8025 | Email capture |
| adminer | adminer | 8080 | Database management |

## LLM Agent Integration

### Connecting an Agent

Add the Playwright MCP server to your agent's MCP configuration:

```json
{
  "mcpServers": {
    "playwright": {
      "url": "http://localhost:3000/sse"
    }
  }
}
```

The agent can then use Playwright MCP tools to interact with WordPress:

- `browser_navigate` — Navigate to URLs
- `browser_click` — Click elements
- `browser_type` — Type into form fields
- `browser_screenshot` — Capture screenshots
- `browser_snapshot` — Get accessibility tree (DOM structure)
- `browser_evaluate` — Run JavaScript in the page

### Internal URLs (from Playwright container)

Inside the Docker network, WordPress is at `http://sportspress-test`. The agent should use this URL for browser navigation since Playwright runs inside the same Docker network.

### Hybrid Testing Strategy

The environment supports three testing channels:

1. **Browser automation** (Playwright MCP) — UI interactions, form submissions, visual verification
2. **REST API** — Data verification at `http://localhost:8082/wp-json/`
3. **WP-CLI** — State management via `docker exec sportspress-test wp ... --allow-root`

### Health Endpoint

The REST API health endpoint verifies environment readiness:

```bash
curl http://localhost:8082/wp-json/test/v1/health
```

Returns:

```json
{
  "status": "ready",
  "wordpress": "6.9.4",
  "sportspress": "2.7.29",
  "sport": "ice-hockey",
  "plugins": ["sportspress", "sportspress-admin-tools", ...],
  "theme": "developer",
  "timestamp": "2026-04-16T18:30:00+00:00"
}
```

### Database State Reset

A baseline database snapshot is created during container setup. Reset between test suites:

```bash
# From host
./tests/reset-state.sh

# Or manually
docker exec sportspress-test wp db import /tmp/baseline.sql --allow-root
docker exec sportspress-test wp cache flush --allow-root
```

## Test Suites

Test suites are agent-readable markdown files in `tests/suites/`. Each file contains step-by-step instructions an LLM agent can follow using Playwright MCP.

| Suite | File | Tests | Coverage |
|-------|------|-------|----------|
| Smoke Tests | 00-smoke.md | 7 | Environment readiness, auto-login, plugin activation |
| Admin Tools Core | 01-admin-tools-core.md | 8 | Settings, tabs, modules, notifications, health dashboard |
| Events Manager | 02-events-manager.md | 9 | Calendars, league tables, season rollover |
| Schedule Generator | 03-schedule-generator.md | 27 | Config CRUD, generation, export, import, constraints |
| Player Tools | 04-player-tools.md | 10 | Email meta, captain, stats, batch list creator |
| League Manager | 05-league-manager.md | 14 | Dashboard, rosters, fees, health checker |
| Player Registration | 06-player-registration.md | 10 | Settings, auto-create, duplicate detection |
| e-Transfer Automation | 07-etransfer-automation.md | 15 | Webhooks, HMAC auth, manual match, logging |

Total: ~100 test cases covering every feature of SportsPress Admin Tools.

### Running Tests

```bash
# Run a single suite
./tests/run-suite.sh tests/suites/00-smoke.md

# Run all suites in order
./tests/run-suite.sh all
```

### Test Result Format

Agents produce JSON results that can be converted to JUnit XML:

```bash
# Convert JSON results to JUnit XML
node tests/report-converter.js results.json report.xml

# Or via stdin
cat results.json | node tests/report-converter.js > report.xml
```

See `tests/README.md` for the full JSON schema and writing guide.

## Sports Available

Set `SPORTSPRESS_SPORT` environment variable:

- `soccer` (default), `basketball`, `baseball`, `ice-hockey`
- `american-football`, `rugby-league`, `rugby-union`, `volleyball`
- `australian-football`, `cricket`, `floorball`, `football`
- `handball`, `netball`

## Features

- **Auto-Login** — Automatically logged in as admin (no credentials needed)
- **Debug Tools** — Query Monitor, Debug Bar, and User Switching pre-installed
- **MCP Server** — WordPress MCP Server plugin installed (inactive by default)
- **Abilities API** — WordPress Abilities API plugin installed (inactive by default)
- **DB Baseline** — Snapshot at `/tmp/baseline.sql` for state reset between tests
- **REST Health** — `/wp-json/test/v1/health` for readiness checks

## CI/CD

The `agent-tests.yml` workflow runs on push to main and pull requests:

1. Builds the Docker Compose environment
2. Waits for the health endpoint
3. Runs smoke tests (health API + wp-admin accessibility)
4. Collects screenshots and test results as artifacts

## Project Structure

```text
├── Dockerfile                          # WordPress + SportsPress container
├── compose.yml                         # All services with Playwright MCP
├── config/
│   ├── scripts/
│   │   ├── setup-test-data.sh          # WordPress + SportsPress setup + DB baseline
│   │   ├── start.sh                    # Container entrypoint
│   │   └── generate-extra-data.php     # Additional SportsPress data
│   ├── wordpress/
│   │   ├── wp-config.php               # WordPress configuration
│   │   └── mu-plugins/
│   │       ├── auto-login.php          # Auto-login for testing
│   │       └── rest-api-health.php     # Health endpoint for agents
│   ├── nginx/                          # Nginx configuration
│   ├── php/                            # PHP-FPM + Xdebug configuration
│   ├── mariadb/                        # MariaDB configuration
│   └── supervisor/                     # Process management
├── tests/
│   ├── README.md                       # Test framework documentation
│   ├── reset-state.sh                  # Database state reset
│   ├── run-suite.sh                    # Test suite orchestrator
│   ├── report-converter.js             # JSON → JUnit XML converter
│   └── suites/                         # Agent-readable test plans
│       ├── 00-smoke.md
│       ├── 01-admin-tools-core.md
│       ├── 02-events-manager.md
│       ├── 03-schedule-generator.md
│       ├── 04-player-tools.md
│       ├── 05-league-manager.md
│       ├── 06-player-registration.md
│       └── 07-etransfer-automation.md
└── .github/workflows/
    ├── agent-tests.yml                 # LLM agent test pipeline
    ├── build-image.yml                 # Docker image build
    └── check-updates.yml               # Dependency update checks
```

## External Database

To use an external database instead of the bundled MariaDB:

```bash
docker run -p 8082:80 \
  -e WORDPRESS_DB_HOST=my-db-host \
  -e WORDPRESS_DB_USER=my-user \
  -e WORDPRESS_DB_PASSWORD=my-password \
  -e WORDPRESS_DB_NAME=my-db \
  sportspress-test-env
```
