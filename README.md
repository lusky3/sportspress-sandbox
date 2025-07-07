# SportsPress Docker Test Environment

Complete WordPress + SportsPress test environment with automated sample data installation.

## Quick Start

```bash
# Build and run
docker build -f Dockerfile.testenv -t sportspress-test-env .
docker run -p 8082:80 sportspress-test-env

# Or use docker-compose
docker-compose up

# Access at http://localhost:8082
# Admin: admin/admin
```

## Sports Available

Set `SPORTSPRESS_SPORT` environment variable:

- `soccer` (default in compose)
- `basketball`, `baseball`, `ice-hockey`
- `american-football`, `rugby-league`, `volleyball`
- And more...

## Structure

- `config/` - All configuration files organized by service
- `.github/workflows/` - CI/CD automation
- `Dockerfile` - Main container definition
- `compose.yml` - Local development setup
