<?php
/**
 * Template Name: Blank
 *
 * @package ALiEMU
 */

get_header();
?>

<section id="content">
	<div class="content-area">
		<main role="main">
			<?php if ( have_posts() ) : ?>
				<?php the_post(); ?>
				<article id="post-<?php the_ID(); ?>" <?php post_class(); ?>>
					<?php the_content(); ?>
				</article>
			<?php endif; ?>
		</main>
	<div>
</section>

<?php
get_footer();
