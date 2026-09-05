# TODO: `sp_season` taxonomy never registers in this environment

Found 2026-08-25 while seeding an E2E fixture for a different project
(rookiehockey-blueline's homepage standings tab strip). Writing this down
here since it's this repo's bug, not that one's.

## The bug

SportsPress core (`ThemeBoy/SportsPress`, `includes/class-sp-post-types.php`,
`SP_Post_types::register_taxonomies()`) only registers the `sp_season`
taxonomy when this resolves truthy:

```php
if ( apply_filters( 'sportspress_has_seasons', true ) ) :
    ...
    register_taxonomy( 'sp_season', $object_types, $args );
endif;
```

In this sandbox image, that filter resolves **false** — confirmed live,
twice, in a real running container:

```
$ wp term create sp_season "Test" --allow-root
Error: Invalid taxonomy.

$ wp eval-file some-script-calling-wp_insert_term.php --allow-root
Failed to create sp_season term: Invalid taxonomy.
```

I didn't track down *what* filters it to false (some other plugin, a
setting, or SportsPress's own conditional logic based on the active sport
preset) — that's the actual thing to find. Whatever it is, it means
`sp_season` is unusable out of the box here, even though it's a real,
core-registered taxonomy that production sites (rookiehockey.ca) use
constantly.

## It's already silently breaking `generate-extra-data.php`

`config/scripts/generate-extra-data.php`'s own `create_sp_term()` helper
(line 16) *does* check `is_wp_error()` on `wp_insert_term()` and echoes an
error + returns `false` — so every image build has almost certainly been
printing something like:

```
❌ Error creating term 2024: Invalid taxonomy.
❌ Error creating term 2025: Invalid taxonomy.
```

...into the build log (worth grepping a real build log to confirm), with
`$season_ids` ending up empty. Everything downstream that assumes real
season ids exist is suspect:

- `$season_id = array_values($season_ids)[0];` (line 140) — undefined
  array key, `$season_id` ends up `null`.
- Every `wp_set_object_terms( ..., 'sp_season' )` call for teams/players/
  staff/events/tables/lists/calendars (lines 74, 107, 133, 166, 204, 220,
  236) either sets nothing or sets `[null]`.

None of this fails the build (the script has no `set -e`-style bailout on
these particular errors), so it's been quietly not doing what it claims to
for however long this has been the case. Worth actually checking a build
log rather than assuming — I haven't done that, just traced the code path.

## Suggested fix (pick one)

1. **Find and fix the actual filter source.** Grep the built image's active
   plugins for `sportspress_has_seasons` (or whatever adds a filter on it)
   and see why it's forcing `false`. This is the "real" fix if some other
   plugin or setting is doing this on purpose for a reason that no longer
   applies.
2. **Cheaper workaround**: add `add_filter( 'sportspress_has_seasons', '__return_true' );`
   somewhere early in `config/scripts/setup-test-data.sh` (or a small
   mu-plugin), before `generate-extra-data.php` runs. Doesn't explain the
   root cause, but unblocks season data reliably regardless of what's
   filtering it.
3. Once fixed, re-check `create_sp_term()`'s own error path actually stops
   firing for `sp_season`, and that `$season_id` downstream is a real int,
   not null.

## How I worked around it on the consuming side (for reference)

In the other project's E2E fixture, rather than depend on this repo's
behavior, I had the fixture script register `sp_season` itself if
`taxonomy_exists('sp_season')` is false, using the same object types core
registers it against. That's a fine permanent workaround for *that*
project either way, but it means this repo's own bug can keep hiding here
unless something else surfaces it.
