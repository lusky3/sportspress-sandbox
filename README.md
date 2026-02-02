# SportsPress Docker Test Environment

Complete WordPress + SportsPress test environment with automated sample data installation.

## Quick Start

```bash
# Build and run
docker build -f Dockerfile -t sportspress-test-env .
docker run -p 8082:80 sportspress-test-env

# Or use docker-compose
docker-compose up

# Access at http://localhost:8082
# Admin: admin/admin
# Mailhog: http://localhost:8025
# Adminer: http://localhost:8080

## New Features
- **Auto-Login**: You are automatically logged in as admin when visiting the site.
- **Debug Tools**: Query Monitor, Debug Bar, and User Switching are pre-installed and active.
- **MCP Server**: The WordPress MCP Server plugin is installed but inactive.
- **Abilities API**: The WordPress Abilities API plugin is installed but inactive.
```

## Sports Available

Set `SPORTSPRESS_SPORT` environment variable:

- `soccer` (default in compose)
- `basketball`, `baseball`, `ice-hockey`
- `american-football`, `rugby-league`, `volleyball`
- And more...

## External Database

To use an external database instead of the bundled MariaDB, set the `WORDPRESS_DB_HOST` environment variable. The internal MariaDB service will be disabled.

```bash
docker run -p 8082:80 \
  -e WORDPRESS_DB_HOST=my-db-host \
  -e WORDPRESS_DB_USER=my-user \
  -e WORDPRESS_DB_PASSWORD=my-password \
  -e WORDPRESS_DB_NAME=my-db \
  sportspress-test-env
```

## Structure

- `config/` - All configuration files organized by service
- `.github/workflows/` - CI/CD automation
- `Dockerfile` - Main container definition
- `compose.yml` - Local development setup
