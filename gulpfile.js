var gulp = require('gulp');
var gutil = require('gulp-util');
var concat = require('gulp-concat');
var coffee = require('gulp-coffee');
var zip = require('gulp-zip');

gulp.task('default', ['build-notepad.js', 'copy-vendor', 'copy-resources', 'watch']);

gulp.task('build-notepad.js', function() {
	return gulp.src('src/js/**/*.coffee')
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
