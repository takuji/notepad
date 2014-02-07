class Notepad extends Backbone.Model
  initialize: (attrs, options)->
    @scenes = ['notes', 'note-edit']
    @current_scene = @scenes[0]
    @documents = options.documents || new Backbone.Collection()
    console.log 'Application initialized.'

  getNote: (note_id)->
    @documents.get(note_id)


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
    @app.changeNote(id)
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
    $window = $(window)
    $window.on 'resize', => @resize()
    $window.on 'keydown', (e)=> @onKeyDown(e)
    @router = new Router(app: @)
    @router.list()
    @keymaps = {global: new Keymap()}
    #@keymap.set(Key.fromChar('P'), new KeyAction((-> alert('hoge'))))
    Backbone.history.start()

  changeScene: (scene_id)->
    scene = @scenes[scene_id]
    @keymaps['scene'] = scene.keymap
    @sceneRegion.show @scenes[scene_id]

  changeNote: (note_id)->
    @scenes['note_edit'].changeNote(note_id)

  resize: ->
    $scene = $('#scene')
    margin = $scene.offset().top
    $scene.height($(window).height() - margin)

  onKeyDown: (e)->
    key = Key.fromEvent(e)

    action = @keymaps.global.get(key)
    if action
      action.fire()
    action = @keymaps.scene.get(key)
    if action
      action.fire


notes = new Backbone.Collection([
  new Note(id: 1, title: 'ネコ', content: '吾輩は猫である。', created_at: new Date(), updated_at: new Date())
  new Note(id: 2, title: 'いぬ', content: '名前はまだない。', created_at: new Date(), updated_at: new Date())
  new Note(id: 3, title: '猿', content: 'にゃーん。', created_at: new Date(), updated_at: new Date())
  ])

notepad = new Notepad({}, documents: notes)

app = new App()
app.addInitializer (options)->
  app.init(notepad)
app.start()
