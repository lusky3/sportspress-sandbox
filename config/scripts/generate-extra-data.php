<?php
/**
 * Generate extra SportsPress data
 *
 * This script creates missing SportsPress post types, taxonomies, and relationships
 * to ensure a fully populated test environment.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
}

echo "🏗️  Generating extra SportsPress data...\n";

// Helper function to create term if not exists
function create_sp_term( $term_name, $taxonomy ) {
	$term = get_term_by( 'name', $term_name, $taxonomy );
	if ( ! $term ) {
		$term_data = wp_insert_term( $term_name, $taxonomy );
		if ( is_wp_error( $term_data ) ) {
			echo "❌ Error creating term $term_name: " . $term_data->get_error_message() . "\n";
			return false;
		}
		return $term_data['term_id'];
	}
	return $term->term_id;
}

// 1. Create Leagues
$leagues = [ 'Premier League', 'Championship' ];
$league_ids = [];
foreach ( $leagues as $league ) {
	$id = create_sp_term( $league, 'sp_league' );
	if ( $id ) $league_ids[$league] = $id;
}

// 2. Create Seasons
$seasons = [ '2024', '2025' ];
$season_ids = [];
foreach ( $seasons as $season ) {
	$id = create_sp_term( $season, 'sp_season' );
	if ( $id ) $season_ids[$season] = $id;
}

// 3. Create Positions
$positions = [ 'Goalkeeper', 'Defender', 'Midfielder', 'Forward' ];
$position_ids = [];
foreach ( $positions as $position ) {
	$id = create_sp_term( $position, 'sp_position' );
	if ( $id ) $position_ids[$position] = $id;
}

// 4. Create Teams
$teams = [ 'Red Dragons', 'Blue Sharks', 'Green Giants', 'Yellow Submarines' ];
$team_ids = [];

foreach ( $teams as $team_name ) {
	$team_id = post_exists( $team_name, '', '', 'sp_team' );
	if ( ! $team_id ) {
		$team_id = wp_insert_post( [
			'post_title'  => $team_name,
			'post_type'   => 'sp_team',
			'post_status' => 'publish',
		] );
		echo "✅ Created Team: $team_name ($team_id)\n";
	} else {
		// echo "ℹ️  Team exists: $team_name ($team_id)\n";
	}
	
	if ( $team_id ) {
		$team_ids[] = $team_id;
		// Assign to all leagues and seasons for simplicity
		wp_set_object_terms( $team_id, array_values( $league_ids ), 'sp_league' );
		wp_set_object_terms( $team_id, array_values( $season_ids ), 'sp_season' );
	}
}

// 5. Create Players
$player_names = [
	'John Doe', 'Jane Smith', 'Mike Johnson', 'Emily Davis',
	'Chris Wilson', 'Sarah Brown', 'David Lee', 'Lisa Taylor',
	'Tom Clark', 'Anna White', 'James Green', 'Patricia Hall'
];

foreach ( $player_names as $index => $player_name ) {
	$player_id = post_exists( $player_name, '', '', 'sp_player' );
	if ( ! $player_id ) {
		$player_id = wp_insert_post( [
			'post_title'  => $player_name,
			'post_type'   => 'sp_player',
			'post_status' => 'publish',
		] );
		echo "✅ Created Player: $player_name ($player_id)\n";
	}
	
	if ( $player_id ) {
		// Assign random position
		$random_position = array_values($position_ids)[array_rand($position_ids)];
		wp_set_object_terms( $player_id, [ $random_position ], 'sp_position' );
		
		// Assign to a team (round robin)
		$team_id = $team_ids[ $index % count( $team_ids ) ];
		wp_set_object_terms( $player_id, [ $team_id ], 'sp_team' );
		
		// Assign to leagues and seasons
		wp_set_object_terms( $player_id, array_values( $league_ids ), 'sp_league' );
		wp_set_object_terms( $player_id, array_values( $season_ids ), 'sp_season' );
		
		// Set current team meta
		update_post_meta( $player_id, 'sp_current_team', $team_id );
		
		// Set metrics (random)
		update_post_meta( $player_id, 'sp_number', rand( 1, 99 ) );
	}
}

// 6. Create Staff
$staff_names = [ 'Coach Carter', 'Manager Mike', 'Trainer Tom' ];
foreach ( $staff_names as $staff_name ) {
	$staff_id = post_exists( $staff_name, '', '', 'sp_staff' );
	if ( ! $staff_id ) {
		$staff_id = wp_insert_post( [
			'post_title'  => $staff_name,
			'post_type'   => 'sp_staff',
			'post_status' => 'publish',
		] );
		echo "✅ Created Staff: $staff_name ($staff_id)\n";
	}
	
	if ( $staff_id ) {
		$team_id = $team_ids[ array_rand( $team_ids ) ];
		wp_set_object_terms( $staff_id, [ $team_id ], 'sp_team' );
		wp_set_object_terms( $staff_id, array_values( $season_ids ), 'sp_season' );
		wp_set_object_terms( $staff_id, array_values( $league_ids ), 'sp_league' );
	}
}

// 7. Create Events (Matches)
// Create a few matches for the first season and first league
$season_id = array_values($season_ids)[0];
$league_id = array_values($league_ids)[0];

for ( $i = 0; $i < 6; $i++ ) {
	// Random home and away teams
	$home_team = $team_ids[ array_rand( $team_ids ) ];
	$away_team = $team_ids[ array_rand( $team_ids ) ];
	
	while ( $home_team == $away_team ) {
		$away_team = $team_ids[ array_rand( $team_ids ) ];
	}
	
	$match_title = get_the_title( $home_team ) . ' vs ' . get_the_title( $away_team );
	
	$event_id = post_exists( $match_title, '', '', 'sp_event' );
	if ( ! $event_id ) {
		$event_id = wp_insert_post( [
			'post_title'  => $match_title,
			'post_type'   => 'sp_event',
			'post_status' => 'publish',
		] );
		echo "✅ Created Event: $match_title ($event_id)\n";
	}
	
	if ( $event_id ) {
		wp_set_object_terms( $event_id, [ $league_id ], 'sp_league' );
		wp_set_object_terms( $event_id, [ $season_id ], 'sp_season' );
		wp_set_object_terms( $event_id, [ $home_team, $away_team ], 'sp_team' );
		
		// Set results (random)
		$home_score = rand( 0, 5 );
		$away_score = rand( 0, 5 );
		
		$results = [
			$home_team => [ 'outcome' => [ 'main' => $home_score ] ],
			$away_team => [ 'outcome' => [ 'main' => $away_score ] ],
		];
		
		update_post_meta( $event_id, 'sp_results', $results );
		
		// Set date (random past/future)
		$days = rand( -10, 10 );
		$date = date( 'Y-m-d H:i:s', strtotime( "$days days" ) );
		wp_update_post( [
			'ID' => $event_id,
			'post_date' => $date,
			'post_date_gmt' => $date,
		] );
	}
}

// 8. Create League Table
$table_title = 'League Table ' . $seasons[0];
$table_id = post_exists( $table_title, '', '', 'sp_table' );
if ( ! $table_id ) {
	$table_id = wp_insert_post( [
		'post_title'  => $table_title,
		'post_type'   => 'sp_table',
		'post_status' => 'publish',
	] );
	echo "✅ Created Table: $table_title ($table_id)\n";
}
if ( $table_id ) {
	wp_set_object_terms( $table_id, [ $league_id ], 'sp_league' );
	wp_set_object_terms( $table_id, [ $season_id ], 'sp_season' );
}

// 9. Create Player List
$list_title = 'Player List ' . $seasons[0];
$list_id = post_exists( $list_title, '', '', 'sp_list' );
if ( ! $list_id ) {
	$list_id = wp_insert_post( [
		'post_title'  => $list_title,
		'post_type'   => 'sp_list',
		'post_status' => 'publish',
	] );
	echo "✅ Created Player List: $list_title ($list_id)\n";
}
if ( $list_id ) {
	wp_set_object_terms( $list_id, [ $league_id ], 'sp_league' );
	wp_set_object_terms( $list_id, [ $season_id ], 'sp_season' );
}

// 10. Create Calendar
$calendar_title = 'Calendar ' . $seasons[0];
$calendar_id = post_exists( $calendar_title, '', '', 'sp_calendar' );
if ( ! $calendar_id ) {
	$calendar_id = wp_insert_post( [
		'post_title'  => $calendar_title,
		'post_type'   => 'sp_calendar',
		'post_status' => 'publish',
	] );
	echo "✅ Created Calendar: $calendar_title ($calendar_id)\n";
}
if ( $calendar_id ) {
	wp_set_object_terms( $calendar_id, [ $league_id ], 'sp_league' );
	wp_set_object_terms( $calendar_id, [ $season_id ], 'sp_season' );
}

// 11. Create Metrics
$metrics = [ 'Goals', 'Assists', 'Yellow Cards', 'Red Cards' ];
$metric_ids = [];
foreach ( $metrics as $metric_name ) {
	$metric_id = post_exists( $metric_name, '', '', 'sp_metric' );
	if ( ! $metric_id ) {
		$metric_id = wp_insert_post( [
			'post_title'  => $metric_name,
			'post_type'   => 'sp_metric',
			'post_status' => 'publish',
		] );
		echo "✅ Created Metric: $metric_name ($metric_id)\n";
	}
	if ( $metric_id ) {
		$metric_ids[$metric_name] = $metric_id;
	}
}

echo "🎉 Extra SportsPress data generation complete!\n";
