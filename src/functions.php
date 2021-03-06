<?php
/**
 * ALiEMU functions and definitions
 *
 * @link https://developer.wordpress.org/themes/basics/theme-functions/
 *
 * @package ALiEMU
 */

namespace ALIEMU;

defined( 'ABSPATH' ) || exit;

/**
 * Globals
 */
define( 'ALIEMU_VERSION', wp_get_theme()->get( 'Version' ) );
define( 'ALIEMU_VERSION_HASH', hash( 'sha1', ALIEMU_VERSION ) );
define( 'ALIEMU_ROOT_PATH', __DIR__ );
define( 'ALIEMU_ROOT_URI', get_template_directory_uri() );
define(
	'ALIEMU_POST_TYPES',
	[
		'course'      => 'sfwd-courses',
		'lesson'      => 'sfwd-lessons',
		'quiz'        => 'sfwd-quiz',
		'topic'       => 'sfwd-topic',
		'certificate' => 'sfwd-certificates',
	]
);

require_once __DIR__ . '/lib/index.php';
