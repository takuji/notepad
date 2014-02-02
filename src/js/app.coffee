class Notepad extends Backbone.Model
  initialize: (attrs, options)->
    @scenes = ['notes', 'note-edit']
    @current_scene = @scenes[0]
    @documents = options.documents || new Backbone.Collection()
    console.log 'Application initialized.'


class Scenes extends Backbone.Router
  routes:
    'notes': 'list'
    'notes/:id/edit': 'edit'

  initialize: (option)->
    @app = option.app
    @scenes =
      notes: new NotesScene(model: option.model)
      note_edit: new NoteEditScene(model: option.model)
    console.log 'Screens initialized.'

  list: ->
    console.log 'list'
    @showScreen('notes')

  edit: (id)->
    console.log "edit #{id}"
    @showScreen('note_edit')

  showScreen: (screen_id)->
    @app.scene.show @scenes[screen_id]


class App extends Marionette.Application

  init: (notepad)->
    @scene_pane = $('#scene')
    @addRegions scene: '#scene'
    @resize()
    $(window).on 'resize', => @resize()
    @scenes = new Scenes(app: @, model: notepad)
    @scenes.showScreen('notes')
    Backbone.history.start() 

  resize: ->
    $scene = $('#scene')
    margin = $scene.offset().top
    $scene.height($(window).height() - margin)


notes = new Backbone.Collection([
  new Backbone.Model(id: 1, title: 'ネコ', content: '吾輩は猫である。', created_at: new Date())
  new Backbone.Model(id: 2, title: 'いぬ', content: '名前はまだない。', created_at: new Date())
  new Backbone.Model(id: 3, title: '猿', content: 'にゃーん。', created_at: new Date())
  ])

notepad = new Notepad({}, documents: notes)

app = new App()
app.addInitializer (options)->
  app.init(notepad)
app.start()
