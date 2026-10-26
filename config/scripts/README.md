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

Seeds the known player scenario the FreeScout SPAT bridge's end-to-end test asserts against. Run it with a shared secret: `docker exec sportspress-test bash /usr/local/bin/fixtures-freescout-bridge.sh <secret>`. It sets `spat_freescout_secret`, enables `player_modifications`, `player_registration` and `etransfer_automation`, and creates season S2026, division Div 3, teams Ducks and Otters, two players sharing `fixture-bridge@example.test` (Jordan Smith, a Ducks forward and captain with a linked WP user, and Riley Smith on Otters), a future-dated Ducks vs Otters game at Rink 2, and two completed orders for that email, each holding one "FreeScout Bridge Registration (S2026)" product from the `Registration` product category, so SPAT counts them as registration orders (one processed with a `player_created` log row, one unprocessed with a `name_rejected` row). Registration processing is detached while the orders are saved, so the fixture is not altered. It also creates three `spat_etransfer_logs` rows (results are the e-Transfer plugin's own strings): `FIXTURE-MATCHED` (from the fixture email, 325.00, linked to the processed order), `FIXTURE-UNMATCHED` (from `payer-other@example.test`, Pat Smith, 325.00, no order, dated one day after the on-hold order, "No matching order found") and `FIXTURE-MISMATCH` (from the fixture email, 300.00, unmatched); an on-hold order for the fixture email totalling 325.00 (a "FreeScout Bridge e-Transfer Test Item", created without status-transition handlers, so `FIXTURE-UNMATCHED` is its possible match); and two WP users, `admin@example.test` (administrator) and `nocap@example.test` (subscriber). It is idempotent and prints one JSON line: `{"email":"...","player_ids":[...],"team":"Ducks","etransfer_log_id":..,"possible_match_log_id":..,"mismatch_log_id":..,"matched_log_id":..,"on_hold_order_id":..,"agent_email":"admin@example.test","nocap_email":"nocap@example.test"}` (`etransfer_log_id` and `possible_match_log_id` are the `FIXTURE-UNMATCHED` row).
