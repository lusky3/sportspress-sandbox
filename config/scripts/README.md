# Setup Scripts

## setup-test-data.sh

Automated WordPress and SportsPress setup:

- Waits for database readiness
- Installs WordPress with admin/admin credentials
- Installs and configures SportsPress
- Applies sport-specific presets via `SPORTSPRESS_SPORT` env var
- Installs sample data (teams, players, events)
- Activates Rookie theme
