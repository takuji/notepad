class Notepad extends Backbone.Model
  initialize: (attrs, options)->
    @settings = {}
    @scenes = ['notes', 'note-edit']
    @current_scene = @scenes[0]
    @repository = new FileSystemRepository()
    @notes = options.notes || new Backbone.Collection()
    console.log 'Application initialized.'

  getNote: (note_id)->
    @notes.get(note_id)

  updateIndex: (note)->
    if @note_index
      @note_index.updateIndex(note)

  saveNote: (note)->
    @repository.save(note).then(
      (()=>
        console.log "Note #{note.id} is saved successfully"
        @updateIndex(note)
        @repository.saveIndex(@index)),
      ((error)=>
        console.log 'Failed to save'))

  loadIndex: ->
    @repository.loadIndex().then(
      ((index)=>
        @note_index = index),
      ((error) =>
        console.error error))


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
    @keymaps =
      global: new Keymap()
      scene: null
    @addRegions sceneRegion: '#scene'
    @scenes =
      notes: new NotesScene(model: notepad)
      note_edit: new NoteEditScene(model: notepad)
    @resize()
    $window = $(window)
    $window.on 'resize', => @resize()
    $window.on 'keydown', (e)=> @onKeyDown(e)
    # Initialize router
    @router = new Router(app: @)
    @router.list()
    # Load existing notes
    notepad.loadIndex()
    Backbone.history.start()

  changeScene: (scene_id)->
    console.log "Changing scene to #{scene_id}"
    scene = @scenes[scene_id]
    @keymaps.scene = scene.keymap
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
      action.fire()


notes = new NoteCollection([
  new Note(id: 1, title: 'ネコ', content: '吾輩は猫である。', created_at: new Date(), updated_at: new Date())
  new Note(id: 2, title: 'いぬ', content: '名前はまだない。', created_at: new Date(), updated_at: new Date())
  new Note(id: 3, title: '猿', content: 'にゃーん。', created_at: new Date(), updated_at: new Date())
  ])

notepad = new Notepad({}, notes: notes)

app = new App()
app.addInitializer (options)->
  app.init(notepad)
app.start()
