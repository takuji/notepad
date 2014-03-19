module.exports = (grunt)->
  # Project configuration
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    coffee:
      compile:
        options:
          bare: true
        files: [
          expand: true
          cwd: 'src/js/lib/'
          src: ['**/*.coffee']
          dest: 'build/app.nw/js/lib/'
          ext: '.js'          
        ]


  # Plugins
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  # Tasks
  grunt.registerTask 'default', 'test', ->
    grunt.log.write 'Hello world'
