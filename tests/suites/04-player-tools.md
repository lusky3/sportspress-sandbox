# Test Suite: Player Tools

## Prerequisites
- WordPress running at http://sportspress-test with auto-login enabled
- SportsPress core plugin activated
- SPAT Player Tools child plugin activated
- WP-CLI available via `docker exec` or direct shell
- At least one team and one player post exist (create via WP-CLI if needed)

## Test Cases

### TC-04-01: Player Tools Tab on SPAT Settings
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to http://sportspress-test/wp-admin/admin.php?page=spat-settings
2. Look for a "Player Tools" tab or section on the settings page
3. Click the Player Tools tab

**Expected Result:**
- The SPAT settings page loads without errors
- A "Player Tools" tab is visible and clickable
- Clicking the tab reveals Player Tools settings fields

**Verification:**
- Confirm the tab element exists in the DOM
- Confirm no PHP errors or warnings appear on the page

### TC-04-02: Player Modifications — Email Meta Box
**Priority:** High
**Type:** UI

**Steps:**
1. Create a player if none exist: `wp post create --post_type=sp_player --post_title="Test Player 04" --post_status=publish`
2. Navigate to the player edit screen: http://sportspress-test/wp-admin/post.php?post={PLAYER_ID}&action=edit
3. Look for an "Email" or "Player Email" meta box on the edit screen
4. Enter a test email address `testplayer@example.com` in the email field
5. Click "Update" to save the player

**Expected Result:**
- An email meta box appears on the player edit screen
- The email value saves without error

**Verification:**
- Reload the player edit page and confirm the email value persists
- Verify via WP-CLI: `wp post meta get {PLAYER_ID} sp_email` returns `testplayer@example.com`

### TC-04-03: Player Modifications — Captain Selection
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the player edit screen for the test player
2. Look for a "Captain" checkbox or selection field
3. Enable/check the captain option
4. Click "Update" to save

**Expected Result:**
- A captain selection control is present on the player edit screen
- The captain flag saves successfully

**Verification:**
- Reload the page and confirm the captain option remains checked
- Verify via WP-CLI: `wp post meta get {PLAYER_ID} sp_captain` returns a truthy value

### TC-04-04: Player Modifications — Squad Number
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the player edit screen for the test player
2. Look for a "Squad Number" or "Number" field
3. Enter `10` as the squad number
4. Click "Update" to save

**Expected Result:**
- A squad number field is present on the player edit screen
- The value saves without error

**Verification:**
- Reload the page and confirm the squad number field shows `10`
- Verify via WP-CLI: `wp post meta get {PLAYER_ID} sp_number` returns `10`

### TC-04-05: Player Stats Enabler Toggle
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to http://sportspress-test/wp-admin/admin.php?page=spat-settings
2. Click the Player Tools tab
3. Locate the "Player Stats Enabler" or "Enable Frontend Stats" toggle
4. Enable the toggle if it is off (or toggle it to the opposite state)
5. Save settings

**Expected Result:**
- The toggle control is present and functional
- Settings save without error
- A success notice appears after saving

**Verification:**
- Reload the settings page and confirm the toggle state persisted
- Navigate to a player's frontend page and check if stats are displayed (when enabled)

### TC-04-06: Batch List Creator — Page Loads
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to http://sportspress-test/wp-admin/tools.php?page=upload-player-lists (or locate via Tools menu)
2. If the exact URL differs, check the Tools menu for "Upload Player Lists" submenu item

**Expected Result:**
- The "Upload Player Lists" page loads without errors
- The page contains a CSV upload form

**Verification:**
- Confirm the page title contains "Player Lists" or similar
- Confirm a file upload input is present on the page

### TC-04-07: Batch List Creator — CSV Upload
**Priority:** Critical
**Type:** Hybrid

**Steps:**
1. Create a test CSV file via WP-CLI: `echo "Team,Name\nTest Team,Player One\nTest Team,Player Two" > /tmp/test-players.csv`
2. Navigate to the Upload Player Lists page
3. Upload the CSV file using the file input
4. Submit the upload form

**Expected Result:**
- The CSV is accepted and parsed
- The page shows the parsed data with Team and Name columns recognized
- No validation errors for the required columns

**Verification:**
- Confirm the upload response shows the correct number of rows (2 players)
- Confirm Team and Name columns are identified

### TC-04-08: Batch List Creator — AJAX Team/Player Search
**Priority:** Medium
**Type:** UI

**Steps:**
1. On the Upload Player Lists page, locate the team or player search field
2. Type a partial team name (e.g., "Test") into the search field
3. Wait for AJAX autocomplete results to appear

**Expected Result:**
- An AJAX request fires as the user types
- Matching teams/players appear in a dropdown or suggestion list

**Verification:**
- Confirm the AJAX response returns results (check network tab or visible dropdown)
- Confirm the search results include the expected team/player

### TC-04-09: Batch List Creator — Player List Creation
**Priority:** High
**Type:** Hybrid

**Steps:**
1. After uploading the CSV in TC-04-07, proceed to create the player list
2. Click the "Create" or "Import" button to finalize the player list
3. Wait for the process to complete

**Expected Result:**
- Player list is created successfully
- A success message is displayed
- Players from the CSV are associated with the correct team

**Verification:**
- Verify via WP-CLI: `wp post list --post_type=sp_list --fields=ID,post_title` shows the new list
- Verify via WP-CLI: `wp post list --post_type=sp_player --fields=ID,post_title` includes "Player One" and "Player Two"

### TC-04-10: Settings Toggles Save Correctly
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to http://sportspress-test/wp-admin/admin.php?page=spat-settings
2. Click the Player Tools tab
3. Note the current state of all toggles/checkboxes
4. Toggle each setting to the opposite state
5. Save settings
6. Reload the page

**Expected Result:**
- All toggled settings persist their new state after reload
- No settings revert to their previous values

**Verification:**
- Compare each toggle state before and after reload — they must match
- Verify via WP-CLI: `wp option get spat_player_tools_settings` (or equivalent option name) reflects the saved values
