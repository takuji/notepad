class Notepad extends Backbone.Model
  initialize: (attrs, options)->
    @scenes = ['notes', 'note-edit']
    @current_scene = @scenes[0]
    @documents = options.documents || new Backbone.Collection()
    console.log 'Application initialized.'


class Router extends Backbone.Router
  routes:
    'notes': 'list'
    'notes/:id/edit': 'edit'

  initialize: (option)->
    @app = option.app
    console.log 'Router initialized.'

  list: ->
    console.log 'list'
    @showScreen('notes')

  edit: (id)->
    console.log "edit #{id}"
    @showScreen('note_edit')

  showScreen: (scene_id)->
    @app.changeScene(scene_id)



class App extends Marionette.Application

  init: (notepad)->
    @addRegions sceneRegion: '#scene'
    @scenes =
      notes: new NotesScene(model: notepad)
      note_edit: new NoteEditScene(model: notepad)
    @resize()
    $(window).on 'resize', => @resize()
    @router = new Router(app: @)
    @router.list()
    Backbone.history.start()

  changeScene: (scene_id)->
    @sceneRegion.show @scenes[scene_id]

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
