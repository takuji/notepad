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

class Key
  constructor: (e)->
    @code = e.keyCode
    @shift = e.shiftKey
    @ctrl = (e.ctrlKey && !e.metaKey) || (!e.ctrlKey && e.metaKey)

  toMapKey: ->
    "#{@ctrl}-#{@shift}-#{@code}"

  codeToString: (code)->
    if code >= 48 && code <= 122
      String.fromCharCode(code)
    else
      switch code
        when  9 then 'TAB'
        when 13 then 'ENTER'
        when 46 then 'DELETE'

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
    @keymaps = {}
    Backbone.history.start()

  changeScene: (scene_id)->
    scene = @scenes[scene_id]
    #@attachKeymap('scene', scene.keymap)
    @sceneRegion.show @scenes[scene_id]

  attachKeymap: (keymap_id, keymap)->
    @keymaps[keymap_id] = keymap

  changeNote: (note_id)->
    @scenes['note_edit'].changeNote(note_id)

  resize: ->
    $scene = $('#scene')
    margin = $scene.offset().top
    $scene.height($(window).height() - margin)

  onKeyDown: (e)->
    key =
      code: e.keyCode
      shift: e.shiftKey
      ctrl: (e.ctrlKey && !e.metaKey) || (!e.ctrlKey && e.metaKey)
    @triggerKeyCommand(key)  

  triggerKeyCommand: (key)->


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
