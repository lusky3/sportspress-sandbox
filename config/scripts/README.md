# Setup Scripts

## setup-test-data.sh

Automated WordPress and SportsPress setup:

- Waits for database readiness
- Installs WordPress with admin/admin credentials
- Installs and configures SportsPress
- Applies sport-specific presets via `SPORTSPRESS_SPORT` env var
- Installs sample data (teams, players, events)
- Activates Rookie theme

## fixtures-freescout-bridge.sh

Seeds the known player scenario the FreeScout SPAT bridge's end-to-end test asserts against. Run it with a shared secret: `docker exec sportspress-test bash /usr/local/bin/fixtures-freescout-bridge.sh <secret>`. It sets `spat_freescout_secret`, enables `player_modifications` and `player_registration`, and creates season S2026, division Div 3, teams Ducks and Otters, two players sharing `fixture-bridge@example.test` (Jordan Smith, a Ducks forward and captain with a linked WP user, and Riley Smith on Otters), a future-dated Ducks vs Otters game at Rink 2, and two completed orders for that email (one processed with a `player_created` log row, one unprocessed with a `name_rejected` row). Registration processing is detached while the orders are saved, so the fixture is not altered. It is idempotent and prints one JSON line: `{"email":"...","player_ids":[...],"team":"Ducks"}`.
