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



  # Plugins
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  # Tasks
  grunt.registerTask 'default', 'test', ->
    grunt.log.write 'Hello world'
