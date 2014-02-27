var gulp = require('gulp');
var gutil = require('gulp-util');
var concat = require('gulp-concat');
var coffee = require('gulp-coffee');
var zip = require('gulp-zip');
var compass = require('gulp-compass');
fs = require('fs');

var BUILD_DIR = 'build',
		DEST_DIR  = BUILD_DIR + '/app.nw',
		MOD_DIR   = DEST_DIR + '/node_modules';

if (!fs.existsSync(BUILD_DIR)) {
	fs.mkdirSync(BUILD_DIR);
}
if (!fs.existsSync(DEST_DIR)) {
	fs.mkdirSync(DEST_DIR);
}
if (!fs.existsSync(MOD_DIR)) {
	fs.mkdirSync(MOD_DIR);
}

gulp.task('default', ['build', 'watch']);
gulp.task('build', ['build-notepad.js', 'build-workers', 'compass', 'copy-vendor', 'copy-resources', 'export-package']);

gulp.task('build-notepad.js', function() {
	return gulp.src(['src/js/requirements.coffee',
                   'src/js/lib/*.coffee',
                   'src/js/modules/*.coffee',
                   'src/js/desktop/*.coffee',
                   'src/js/views/*.coffee',
                   'src/js/scenes/*.coffee',
                   'src/js/app.coffee'])
		.pipe(coffee({bare: true}).on('error', gutil.log))
		.pipe(concat('notepad.js'))
		.pipe(gulp.dest(DEST_DIR + '/js/'));
});

gulp.task('build-workers', function() {
	return gulp.src(['src/js/workers/**/*.coffee'])
		.pipe(coffee({bare: true}).on('error', gutil.log))
		.pipe(gulp.dest(DEST_DIR + '/js/'));
});

gulp.task('copy-vendor', function() {
	return gulp.src('vendor/**/*').pipe(gulp.dest(DEST_DIR));
});

gulp.task('copy-resources', function() {
	return gulp.src('resources/**/*').pipe(gulp.dest(DEST_DIR));
});

gulp.task('watch', function () {
  gulp.watch('src/js/**/*.coffee', ['build-notepad.js', 'build-workers']);
  gulp.watch('src/stylesheets/**/*.scss', ['compass']);
  gulp.watch('resources/**/*', ['copy-resources']);
  gulp.watch(DEST_DIR + '/**/*', ['export-package']);
});

gulp.task('package', function() {
	process.chdir(DEST_DIR);
	var result = gulp.src(['./**/*'])
		.pipe(zip('app.nw'))
		.pipe(gulp.dest('../target'));
	process.chdir('../..');
	return result;
});

gulp.task('export-package', ['package'], function() {
	return gulp.src(BUILD_DIR + '/target/app.nw')
		.pipe(gulp.dest('./'))
});

gulp.task('package-mac', function() {
	return gulp.src(['app.nw'])
		.pipe(gulp.dest('mac/Notepad.app/Contents/Resources'));
});

gulp.task('compass', function() {
  return gulp.src('src/stylesheets/notepad.scss')
    .pipe(compass({config_file: './config.rb', sass: 'src/stylesheets', css: DEST_DIR + '/stylesheets'}))
    .pipe(gulp.dest(DEST_DIR + '/stylesheets'));
});
