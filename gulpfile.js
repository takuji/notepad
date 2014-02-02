var gulp = require('gulp');
var gutil = require('gulp-util');
var concat = require('gulp-concat');
var coffee = require('gulp-coffee');
var zip = require('gulp-zip');
var compass = require('gulp-compass');

gulp.task('default', ['build-notepad.js', 'compass', 'copy-vendor', 'copy-resources', 'watch']);

gulp.task('build-notepad.js', function() {
	return gulp.src(['src/js/scenes.coffee', 'src/js/app.coffee'])
		.pipe(coffee({bare: true}).on('error', gutil.log))
		.pipe(concat('notepad.js'))
		.pipe(gulp.dest('build/src/js/'));
});

gulp.task('copy-vendor', function() {
	return gulp.src('vendor/js/**/*.js').pipe(gulp.dest('build/src/js/'));
});

gulp.task('copy-resources', function() {
	return gulp.src('resources/**/*').pipe(gulp.dest('build/src'));
});

gulp.task('watch', function () {
  gulp.watch('src/js/**/*.coffee', ['build-notepad.js']);
  gulp.watch('src/stylesheets/**/*.coffee', ['compass']);
  gulp.watch('resources/**/*', ['copy-resources']);
  gulp.watch('build/src/**/*', ['package']);
});

gulp.task('package', function() {
	process.chdir('build/src');
	var result = gulp.src(['./**/*'])
		.pipe(zip('app.nw'))
		.pipe(gulp.dest('../'));
	process.chdir('../..');
	return result;
});

gulp.task('compass', function() {
  return gulp.src('./src/stylesheets/notepad.scss')
    .pipe(compass({config_file: './config.rb', css: 'build/src'}))
    .pipe(gulp.dest('build/src/stylesheets'));
});
