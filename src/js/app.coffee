class Router extends Backbone.Router
  routes:
    'notes': 'list'
    'notes/new': 'newNote'
    'notes/:id/edit': 'edit'
    'settings': 'settings'
    'history': 'history'

  initialize: (option)->
    @app = option.app

  list: ->
    @app.changeScene('notes')

  edit: (id)->
    @app.changeScene('note_edit', id: id)

  newNote: ->
    @app.createNote

  settings: ->
    @app.changeScene('settings')

  history: ->
    @app.changeScene('history')

#
#
#
class Toolbar extends Backbone.View
  events:
    'click #toolbar-item-new-note': 'onNewNoteClicked'
    'click #dev-tools': 'onDevToolsClicked'

  initialize: ->
    @listenTo @model, 'current_note_changed', @onCurrentNoteChanged
    settings = @model.settings.getToolbarSettings()
    if settings.dev_tools
      @$('#dev-tools').css('display', 'inline-block')

  onNewNoteClicked: (e)->
    console.log 'Toolbar.onNewNoteClicked'
    @model.createNote()
    .then((note)=>
      @model.selectNote(note.id))
    .then((note)=>
      location.href = "#notes/#{note.id}/edit")

  onDevToolsClicked: (e)->
    e.preventDefault()
    Window.get().showDevTools()
    console.log 'Toolbar.onDevToolsClicked'

  onCurrentNoteChanged: (note)->
    @$('.current-note').html(note.get('title'))

#
#
#
class App extends Marionette.Application

  prepareUI: (notepad)->
    @keymaps =
      global: new Keymap()
      scene: null
    @addRegions sceneRegion: '#scene'
    @scenes =
      notes: new NotesScene(model: notepad)
      note_edit: new NoteEditScene(model: notepad)
      settings: new SettingsScene(model: notepad)
      history: new HistoryScene(model: notepad)
    @resize()
    $window = $(window)
    $window.on 'resize', => @resize()
    $window.on 'keydown', (e)=> @onKeyDown(e)
    # Initialize router
    @router = new Router(app: @)
    @router.list()
    @toolbar = new Toolbar(el: $('#toolbar'), model: notepad)
    Backbone.history.start()

  changeScene: (scene_id, options)->
    console.log "Changing scene to #{scene_id}"
    scene = @scenes[scene_id]
    @keymaps.scene = scene.keymap
    scene.onShowing(options) if scene.onShowing?
    @sceneRegion.show @scenes[scene_id]

  resize: ->
    $scene = $('#scene')
    margin = $scene.offset().top
    $window = $(window)
    $scene.height($window.height() - margin)

  saveWindowSize: (win)->
    size =
      x: win.x
      y: win.y
      width: win.width
      height: win.height
    localStorage.window_size = JSON.stringify(size)
    console.log localStorage.window_size

  loadWindowSize: (win)->
    json = localStorage.window_size
    if json
      size = JSON.parse(json)
      if size.x? && size.y? && size.width? && size.height?
        win.moveTo(size.x, size.y)
        win.resizeTo(size.width, size.height)

  onKeyDown: (e)->
    key = Key.fromEvent(e)
    action = @keymaps.global.get(key)
    if action
      action.fire()
    action = @keymaps.scene.get(key)
    if action
      action.fire()

  onClose: ->
    @scenes.note_edit.saveCurrentNote()

app = new App()
win = Window.get()

win.on 'close', ->
  app.onClose().finally(()-> win.close(true))
win.on 'move', (x, y)->
  app.saveWindowSize(win)
win.on 'resize', (w, h)->
  app.saveWindowSize(win)

app.addInitializer (options)->
  notepad = new Notepad()
  app.getNotePad = ()-> notepad
  app.loadWindowSize(win)
  notepad.prepareWorkspace().then(
    (notepad)->
      app.prepareUI(notepad)
    (error)->
      console.log error)
app.start()

