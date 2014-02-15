class Router extends Backbone.Router
  routes:
    'notes': 'list'
    'notes/new': 'newNote'
    'notes/:id/edit': 'edit'
    'settings': 'settings'

  initialize: (option)->
    @app = option.app
    console.log 'Router initialized.'

  list: ->
    console.log 'list'
    @showScreen('notes')

  edit: (id)->
    console.log "edit #{id}"
    @app.changeNoteAsync(id).then(
      ()=> @showScreen('note_edit'))

  newNote: ->
    @app.createNote

  settings: ->
    console.log 'settings'
    @showScreen 'settings'

  showScreen: (scene_id)->
    @app.changeScene(scene_id)

#
#
#
class Toolbar extends Backbone.View
  events:
    'click #toolbar-item-new-note': 'onNewNoteClicked'

  onNewNoteClicked: (e)->
    @model.createNote().then(
      (note)=>
        location.href = "#notes/#{note.id}/edit")



#
#
#
class App extends Marionette.Application

  init: (notepad)->
    @keymaps =
      global: new Keymap()
      scene: null
    @addRegions sceneRegion: '#scene'
    @scenes =
      notes: new NotesScene(model: notepad)
      note_edit: new NoteEditScene(model: notepad)
      settings: new SettingsScene(model: notepad)
    @resize()
    $window = $(window)
    $window.on 'resize', => @resize()
    $window.on 'keydown', (e)=> @onKeyDown(e)
    # Initialize router
    @router = new Router(app: @)
    @router.list()
    @toolbar = new Toolbar(el: $('#toolbar'), model: notepad)
    Backbone.history.start()

  changeScene: (scene_id)->
    console.log "Changing scene to #{scene_id}"
    scene = @scenes[scene_id]
    @keymaps.scene = scene.keymap
    @sceneRegion.show @scenes[scene_id]

  changeNoteAsync: (note_id)->
    @scenes['note_edit'].changeNoteAsync(note_id)

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
      action.fire()

notepad = new Notepad()
notepad.prepareWorkspace().then(
  (notepad)->
    app = new App()
    app.addInitializer (options)->
      app.init(notepad)
    app.start()
  (error)->
    console.log error)

