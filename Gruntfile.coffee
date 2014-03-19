module.exports = (grunt)->
  # Project configuration
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    coffee:
      lib:
        options:
          bare: true
        expand: true
        cwd: 'src/js/lib/'
        src: ['**/*.coffee']
        dest: 'build/app.nw/js/lib/'
        ext: '.js'          
      notepad:
        options:
          bare: true
          join: true
        files:
          'build/app.nw/js/notepad.js': ['src/js/app/**/*.coffee']
      workers:
        options:
          bare: true
        expand: true
        cwd: 'src/js/workers/'
        src: ['**/*.coffee']
        dest: 'build/app.nw/js/workers/'
        ext: '.js'

    compass:
      notepad:
        options:
          sassDir: 'src/stylesheets'
          cssDir: 'build/app.nw/stylesheets'
          specify: 'src/stylesheets/notepad.scss'

    copy:
      vendor:
        files: [
          expand: true
          cwd: 'vendor/'
          src: '**/*'
          dest: 'build/app.nw/'
        ]
      html:
        files: [
          expand: true
          cwd: 'resources'
          src: '**/*'
          dest: 'build/app.nw/'
        ]

  # Plugins
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-compass'

  # Tasks
  grunt.registerTask 'default', ['coffee', 'compass', 'copy']
